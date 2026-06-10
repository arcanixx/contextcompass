/**
 * @file app.config.ts
 * @path app.config.ts
 * @description Expo dynamic config — name, bundle IDs, icons, plugins.
 * @exports default (Expo config)
 * @dependsOn src/config/app.config.ts
 */
import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: process.env.EXPO_PUBLIC_APP_NAME ?? 'KlassMate',
  slug: 'klassmatch',
  version: '0.1.0',
  orientation: 'portrait',
  icon: './assets/icons/app-icon-1024.png',
  scheme: 'klassmatch',
  userInterfaceStyle: 'automatic',
  splash: {
    image: './assets/splash/splash-mobile.png',
    resizeMode: 'cover',
    backgroundColor: '#1E2235',
  },
  ios: {
    supportsTablet: true,
    bundleIdentifier: 'pl.klassmatch.app',
    infoPlist: {
      NSFaceIDUsageDescription: 'Używamy Face ID do szybkiego i bezpiecznego logowania.',
      NSCameraUsageDescription: 'Aparat potrzebny do skanowania notatek i dodawania zdjęć.',
      NSMicrophoneUsageDescription: 'Mikrofon potrzebny do nagrywania wiadomości głosowych.',
    },
  },
  android: {
    package: 'pl.klassmatch.app',
    adaptiveIcon: {
      foregroundImage: './assets/icons/app-icon-android-fg.png',
      backgroundColor: '#1E2235',
    },
    permissions: [
      'CAMERA',
      'RECORD_AUDIO',
      'RECEIVE_BOOT_COMPLETED',
      'VIBRATE',
      'USE_BIOMETRIC',
      'USE_FINGERPRINT',
    ],
  },
  web: {
    bundler: 'metro',
    output: 'static',
    favicon: './assets/icons/favicon-32.png',
  },
  plugins: [
    'expo-router',
    'expo-secure-store',
    ['expo-local-authentication', { faceIDPermission: 'Używamy Face ID do szybkiego logowania.' }],
    ['expo-notifications', { icon: './assets/icons/notification-icon.png', color: '#4F6EF7' }],
    ['expo-screen-capture', { preventScreenCapture: true }],
  ],
  extra: {
    eas: { projectId: 'YOUR_EAS_PROJECT_ID' },
  },
});
