module.exports = {
  root: true,
  env: {
    node: true,           // penting: ini memberitahu ESLint bahwa ini lingkungan Node.js
    es2021: true
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended'
  ],
  ignorePatterns: [
    'lib/**',           // abaikan folder lib (hasil kompilasi tsc)
    'node_modules/**'
  ],
  rules: {
    // Matikan aturan yang sering bikin masalah di Firebase Functions
    'no-undef': 'off',                          // karena global Node.js sudah ditangani env: node
    '@typescript-eslint/no-var-requires': 'off',
    'object-curly-spacing': 'off',
    'key-spacing': 'off',
    'comma-dangle': ['warn', 'never'],
    'comma-spacing': 'off',
    'eol-last': 'off',
    'max-len': ['warn', { code: 120 }],        // naikkan batas jadi 120 supaya lebih longgar
    '@typescript-eslint/no-explicit-any': 'warn'
  }
};