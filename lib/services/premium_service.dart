import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const double premiumAmount = 24000;

  static String get formattedPremiumPrice => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(premiumAmount);

  /* ================= PREMIUM STATUS (30 DAYS TRIAL LOGIC) ================= */

  Stream<bool> getPremiumStatus() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(false);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;
        
        // 1. Cek status premium berbayar
        final bool manualPremium = data['isPremium'] ?? false;
        
        // 2. 🔥 LOGIKA FREEMIUM 1 BULAN (30 HARI)
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        bool isTrialActive = false;
        
        if (createdAt != null) {
          final creationDate = createdAt.toDate();
          final now = DateTime.now();
          final difference = now.difference(creationDate).inDays;
          
          // User free mendapatkan akses penuh selama 30 hari pertama
          if (difference <= 30) {
            isTrialActive = true;
          }
        }

        return manualPremium || isTrialActive;
      });
    });
  }

  Future<void> updatePremiumStatus(bool status) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'isPremium': status,
        'premiumActivatedAt': status ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));
    }
  }

  /* ================= IPAYMU CONFIG & PAYMENT ================= */

  Future<Map<String, String>> getIpaymuConfig() async {
    final doc = await _firestore.collection('settings').doc('payment_gateway').get();
    if (!doc.exists) throw Exception("Konfigurasi tidak ditemukan.");
    final data = doc.data()!;
    return {
      'apiKey': data['ipaymuApiKey'] ?? '',
      'va': data['ipaymuVa'] ?? '',
      'isProduction': data['isProduction'] == true ? 'production' : 'sandbox',
    };
  }

  Future<String?> createIpaymuPaymentLink({
    required String orderId,
    required double amount,
    required String userName,
    required String userEmail,
  }) async {
    try {
      final config = await getIpaymuConfig();
      final String apiKey = config['apiKey']!;
      final String va = config['va']!;
      final bool isProd = config['isProduction'] == 'production';

      final String url = isProd ? "https://my.ipaymu.com/api/v2/payment" : "https://sandbox.ipaymu.com/api/v2/payment";

      final Map<String, dynamic> body = {
        "name": ["Premium Subscription SEPADAN"],
        "qty": ["1"],
        "price": [amount.toInt().toString()],
        "amount": amount.toInt().toString(),
        "returnUrl": "https://sepadan.app/success",
        "cancelUrl": "https://sepadan.app/cancel",
        "notifyUrl": "https://asia-southeast2-sepadanapp.cloudfunctions.net/ipaymuWebhook",
        "referenceId": orderId,
        "buyerName": userName,
        "buyerEmail": userEmail,
        "buyerPhone": "081234567890",
      };

      final jsonBody = jsonEncode(body);
      final bodyHash = sha256.convert(utf8.encode(jsonBody)).toString().toLowerCase();
      final String timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final String stringToSign = "POST:$va:$bodyHash:$apiKey";
      final signature = _hmacSha256(apiKey, stringToSign);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "va": va,
          "signature": signature,
          "timestamp": timestamp,
        },
        body: jsonBody,
      ).timeout(const Duration(seconds: 20));

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 200) {
        return result['data']['url'];
      } else {
        throw Exception("iPaymu Error: ${result['message']}");
      }
    } catch (e) {
      debugPrint("iPaymu Critical Error: $e");
      return null;
    }
  }

  String _hmacSha256(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  Future<String> createTransactionRecord(double amount) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");
    final docRef = await _firestore.collection('payments').add({
      "userId": user.uid,
      "amount": amount,
      "status": "pending",
      "gateway": "ipaymu",
      "createdAt": FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
