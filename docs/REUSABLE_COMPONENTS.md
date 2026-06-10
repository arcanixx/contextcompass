<!--
 FILE: REUSABLE_COMPONENTS.md
 PATH: docs/REUSABLE_COMPONENTS.md
 VERSION: 0.1.0
 PURPOSE: Gotowe do implementacji reużywalne komponenty, hooki i serwisy — kopiuj do projektu bez modyfikacji architektury.
 DEPENDS ON: CODING_STANDARDS.md, ARCHITECTURE_PRINCIPLES.md
-->

# REUSABLE_COMPONENTS.md — Gotowe komponenty i wzorce

> Każdy poniższy blok to **kompletna implementacja** gotowa do skopiowania.
> Dostosuj tylko nazwy projektu, kolory (zmienne CSS) i klucze i18n.

---

## 1. ClearableInput — pole tekstowe z X

```tsx
/*
 * File:       ClearableInput.tsx
 * Path:       packages/web/src/components/common/ClearableInput.tsx
 * Exports:    ClearableInput
 * Depends on: react, react-i18next
 * Purpose:    Input tekstowy z przyciskiem X do czyszczenia — obowiązkowy wzorzec
 */
import { useTranslation } from 'react-i18next';

interface ClearableInputProps {
  value: string;
  onChange: (val: string) => void;
  onClear: () => void;
  label: string;
  placeholder?: string;
  helpText?: string;
  errorText?: string;
  disabled?: boolean;
  required?: boolean;
  maxLength?: number;
  multiline?: boolean;
  rows?: number;
  id?: string;
  className?: string;
}

export function ClearableInput({
  value, onChange, onClear, label, placeholder, helpText,
  errorText, disabled, required, maxLength, multiline, rows = 3, id, className,
}: ClearableInputProps) {
  const { t } = useTranslation();
  const inputId = id ?? `input-${label.replace(/\s/g, '-').toLowerCase()}`;
  const hasError = Boolean(errorText);

  const baseClass = [
    'w-full border rounded-lg px-3 py-2 pr-8 text-sm outline-none transition-colors',
    'focus:ring-2 focus:ring-primary-500 focus:border-primary-500',
    hasError ? 'border-danger-500' : 'border-gray-300',
    disabled ? 'bg-gray-50 text-gray-400 cursor-not-allowed' : 'bg-white',
    className,
  ].filter(Boolean).join(' ');

  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={inputId} className="text-sm font-medium text-gray-700 dark:text-gray-300">
        {label}
        {required && <span className="text-danger-500 ml-1" aria-hidden="true">*</span>}
      </label>

      <div className="relative">
        {multiline ? (
          <textarea
            id={inputId}
            value={value}
            onChange={e => onChange(e.target.value)}
            placeholder={placeholder}
            disabled={disabled}
            rows={rows}
            maxLength={maxLength}
            aria-required={required}
            aria-invalid={hasError}
            aria-describedby={helpText ? `${inputId}-help` : undefined}
            className={`${baseClass} resize-none`}
          />
        ) : (
          <input
            id={inputId}
            type="text"
            value={value}
            onChange={e => onChange(e.target.value)}
            placeholder={placeholder}
            disabled={disabled}
            maxLength={maxLength}
            aria-required={required}
            aria-invalid={hasError}
            aria-describedby={helpText ? `${inputId}-help` : undefined}
            className={baseClass}
          />
        )}

        {value.length > 0 && !disabled && (
          <button
            type="button"
            onClick={onClear}
            aria-label={t('common.clear_field')}
            className={[
              'absolute right-2 top-1/2 -translate-y-1/2',
              'w-5 h-5 flex items-center justify-center',
              'rounded text-gray-400 hover:text-gray-600 hover:bg-gray-100',
              'transition-colors text-xs',
              multiline ? 'top-3 translate-y-0' : '',
            ].filter(Boolean).join(' ')}
          >
            ✕
          </button>
        )}
      </div>

      {helpText && !errorText && (
        <p id={`${inputId}-help`} className="text-xs text-gray-500">{helpText}</p>
      )}
      {errorText && (
        <p className="text-xs text-danger-500" role="alert">{errorText}</p>
      )}
      {maxLength && (
        <p className="text-xs text-gray-400 text-right">{value.length}/{maxLength}</p>
      )}
    </div>
  );
}
```

---

## 2. LoadingButton — przycisk z loading state

```tsx
/*
 * File:       LoadingButton.tsx
 * Path:       packages/web/src/components/common/LoadingButton.tsx
 * Exports:    LoadingButton
 * Depends on: react, react-i18next
 * Purpose:    Przycisk blokujący się podczas async akcji — obowiązkowy wzorzec
 */
import { useTranslation } from 'react-i18next';

type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'outline' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';

interface LoadingButtonProps {
  isLoading: boolean;
  loadingText?: string;
  onClick?: () => void;
  type?: 'button' | 'submit';
  variant?: ButtonVariant;
  size?: ButtonSize;
  disabled?: boolean;
  fullWidth?: boolean;
  children: React.ReactNode;
  className?: string;
  'aria-label'?: string;
}

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
  primary: 'bg-primary-500 text-white hover:bg-primary-600 focus:ring-primary-500',
  secondary: 'bg-gray-100 text-gray-800 hover:bg-gray-200 focus:ring-gray-400',
  danger: 'bg-danger-500 text-white hover:bg-danger-600 focus:ring-danger-500',
  outline: 'bg-transparent border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-gray-400',
  ghost: 'bg-transparent text-gray-600 hover:bg-gray-100 focus:ring-gray-400',
};

const SIZE_CLASSES: Record<ButtonSize, string> = {
  sm: 'px-3 py-1.5 text-xs rounded-md',
  md: 'px-4 py-2 text-sm rounded-lg',
  lg: 'px-6 py-3 text-base rounded-xl',
};

export function LoadingButton({
  isLoading, loadingText, onClick, type = 'button',
  variant = 'primary', size = 'md', disabled, fullWidth,
  children, className, 'aria-label': ariaLabel,
}: LoadingButtonProps) {
  const { t } = useTranslation();
  const isDisabled = isLoading || disabled;

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={isDisabled}
      aria-busy={isLoading}
      aria-label={ariaLabel}
      className={[
        'font-semibold transition-all focus:outline-none focus:ring-2 focus:ring-offset-1',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        fullWidth ? 'w-full' : '',
        className,
      ].filter(Boolean).join(' ')}
    >
      {isLoading ? (
        <span className="flex items-center justify-center gap-2">
          <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
          {loadingText ?? t('common.loading')}
        </span>
      ) : children}
    </button>
  );
}
```

---

## 3. ConfirmDialog — modal potwierdzenia destruktywnych akcji

```tsx
/*
 * File:       ConfirmDialog.tsx
 * Path:       packages/web/src/components/common/ConfirmDialog.tsx
 * Exports:    ConfirmDialog
 * Depends on: react, react-i18next, ./LoadingButton
 * Purpose:    Modal potwierdzenia — WSZYSTKIE destruktywne akcje muszą go używać
 */
import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { LoadingButton } from './LoadingButton';

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  description: string;
  confirmLabel: string;
  confirmVariant?: 'danger' | 'primary';
  cancelLabel?: string;
  isLoading?: boolean;
  /** Gdy podany — użytkownik musi wpisać ten tekst żeby odblokować przycisk confirm */
  requireTyping?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmDialog({
  isOpen, title, description, confirmLabel, confirmVariant = 'danger',
  cancelLabel, isLoading, requireTyping, onConfirm, onCancel,
}: ConfirmDialogProps) {
  const { t } = useTranslation();
  const [typedValue, setTypedValue] = useState('');
  const cancelBtnRef = useRef<HTMLButtonElement>(null);

  // Focus trap — skieruj fokus na Cancel przy otwarciu
  useEffect(() => {
    if (isOpen) {
      setTypedValue('');
      setTimeout(() => cancelBtnRef.current?.focus(), 50);
    }
  }, [isOpen]);

  // Zamknij na Escape
  useEffect(() => {
    if (!isOpen) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onCancel(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, onCancel]);

  if (!isOpen) return null;

  const canConfirm = requireTyping ? typedValue === requireTyping : true;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-dialog-title"
    >
      {/* Overlay */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onCancel}
        aria-hidden="true"
      />

      {/* Modal */}
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <h2 id="confirm-dialog-title" className="text-lg font-bold mb-2">{title}</h2>
        <p className="text-sm text-gray-600 leading-relaxed mb-4">{description}</p>

        {requireTyping && (
          <div className="mb-4">
            <p className="text-xs text-gray-500 mb-2">
              {t('common.confirm_type_label', { word: requireTyping })}
            </p>
            <input
              type="text"
              value={typedValue}
              onChange={e => setTypedValue(e.target.value)}
              placeholder={requireTyping}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-danger-500 outline-none"
              aria-label={t('common.confirm_type_label', { word: requireTyping })}
            />
          </div>
        )}

        <div className="flex justify-end gap-3">
          <button
            ref={cancelBtnRef}
            onClick={onCancel}
            className="px-4 py-2 text-sm font-medium border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            {cancelLabel ?? t('common.cancel')}
          </button>
          <LoadingButton
            variant={confirmVariant}
            isLoading={isLoading ?? false}
            disabled={!canConfirm}
            onClick={onConfirm}
          >
            {confirmLabel}
          </LoadingButton>
        </div>
      </div>
    </div>
  );
}
```

---

## 4. NetworkBanner — pasek offline

```tsx
/*
 * File:       NetworkBanner.tsx
 * Path:       packages/web/src/components/common/NetworkBanner.tsx
 * Exports:    NetworkBanner
 * Depends on: react, react-i18next, shared/services/networkMonitor
 * Purpose:    Sticky baner informujący o braku połączenia — montowany w App.tsx
 */
import { useTranslation } from 'react-i18next';
import { useNetworkStatus } from '../../hooks/useNetworkStatus';

export function NetworkBanner() {
  const { t } = useTranslation();
  const { isOnline, wasOffline } = useNetworkStatus();

  if (isOnline && !wasOffline) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      className={[
        'sticky top-0 z-50 flex items-center justify-center gap-2',
        'px-4 py-2 text-sm font-semibold text-center transition-colors',
        isOnline
          ? 'bg-accent-500 text-white'        // przywrócono połączenie
          : 'bg-warning-500 text-white',       // offline
      ].join(' ')}
    >
      {isOnline ? (
        <><span>✓</span> {t('common.online_restored')}</>
      ) : (
        <><span>📡</span> {t('common.offline_banner')}</>
      )}
    </div>
  );
}
```

---

## 5. ErrorBoundary — łapacz błędów komponentów

```tsx
/*
 * File:       ErrorBoundary.tsx
 * Path:       packages/web/src/components/common/ErrorBoundary.tsx
 * Exports:    ErrorBoundary, ErrorFallback
 * Depends on: react, shared/services/logger
 * Purpose:    Opakowuje każdą stronę — przechwytuje niezłapane błędy renderowania
 */
import { Component, type ReactNode } from 'react';
import { captureError } from 'shared/services/logger';

interface Props { children: ReactNode; fallback?: ReactNode; }
interface State { hasError: boolean; errorId?: string; }

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: { componentStack: string }) {
    const errorId = crypto.randomUUID().slice(0, 8);
    this.setState({ errorId });
    captureError(error, { action: 'ErrorBoundary', extra: { componentStack: info.componentStack, errorId } });
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? <ErrorFallback errorId={this.state.errorId} onRetry={() => this.setState({ hasError: false })} />;
    }
    return this.props.children;
  }
}

function ErrorFallback({ errorId, onRetry }: { errorId?: string; onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-64 p-8 text-center gap-4">
      <div className="text-4xl">⚠️</div>
      <h2 className="text-lg font-bold">Coś poszło nie tak</h2>
      <p className="text-sm text-gray-500 max-w-sm">
        Wystąpił nieoczekiwany błąd. Błąd został automatycznie zgłoszony.
        {errorId && <span className="block mt-1 font-mono text-xs text-gray-400">ID: {errorId}</span>}
      </p>
      <button
        onClick={onRetry}
        className="px-4 py-2 bg-primary-500 text-white rounded-lg text-sm font-semibold hover:bg-primary-600"
      >
        Spróbuj ponownie
      </button>
    </div>
  );
}
```

---

## 6. useNetworkStatus — hook offline/online

```typescript
/*
 * File:       useNetworkStatus.ts
 * Path:       packages/web/src/hooks/useNetworkStatus.ts
 * Exports:    useNetworkStatus
 * Depends on: react
 * Purpose:    Wykrywa stan połączenia sieciowego, symuluje offline w DEV
 */
import { useState, useEffect } from 'react';
import { IS_DEV } from 'shared/constants';

interface NetworkStatus {
  isOnline: boolean;
  wasOffline: boolean; // true przez 3s po powrocie online (do animacji bannera)
}

export function useNetworkStatus(): NetworkStatus {
  // Symulacja offline w DEV przez localStorage flag
  const getIsOnline = () => {
    if (IS_DEV && localStorage.getItem('__simulate_offline') === 'true') return false;
    return navigator.onLine;
  };

  const [isOnline, setIsOnline] = useState<boolean>(getIsOnline);
  const [wasOffline, setWasOffline] = useState(false);

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      setWasOffline(true);
      setTimeout(() => setWasOffline(false), 3000);
    };
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return { isOnline, wasOffline };
}
```

---

## 7. Logger — centralny serwis logowania

```typescript
/*
 * File:       logger.ts
 * Path:       packages/shared/src/services/logger.ts
 * Exports:    logInfo, logWarn, logError, captureError
 * Depends on: shared/constants
 * Purpose:    Centralny logger — w DEV do konsoli, w PROD do Edge Function
 */
import { IS_DEV, APP_VERSION, SUPABASE_FUNCTIONS_URL } from '../constants';

export interface ErrorContext {
  action?: string;
  platform?: 'web' | 'extension' | 'mobile';
  contactId?: string;
  extra?: Record<string, unknown>;
}

const COLORS = {
  info:  '#6366F1',
  warn:  '#F59E0B',
  error: '#EF4444',
};

function devLog(level: 'info' | 'warn' | 'error', category: string, message: string, data?: unknown) {
  const style = `color: ${COLORS[level]}; font-weight: bold`;
  const prefix = `[${level.toUpperCase()}][${category}]`;
  if (data !== undefined) {
    console[level](`%c${prefix}`, style, message, data);
  } else {
    console[level](`%c${prefix}`, style, message);
  }
}

export function logInfo(category: string, message: string, data?: unknown): void {
  if (IS_DEV) devLog('info', category, message, data);
}

export function logWarn(category: string, message: string, data?: unknown): void {
  if (IS_DEV) devLog('warn', category, message, data);
  // Warningi też wysyłamy w PROD jeśli krytyczne — opcjonalnie odkomentuj:
  // else sendToServer('warn', category, message, undefined, data);
}

export function logError(category: string, message: string, error?: unknown): void {
  if (IS_DEV) {
    devLog('error', category, message, error);
  } else {
    void sendToServer('error', category, message, error instanceof Error ? error : undefined);
  }
}

export function captureError(error: Error, context?: ErrorContext): void {
  if (IS_DEV) {
    console.error('[CAPTURED ERROR]', error.message, context, error.stack);
    return;
  }
  void sendToServer('error', context?.action ?? 'unknown', error.message, error, context);
}

async function sendToServer(
  level: string,
  category: string,
  message: string,
  error?: Error,
  context?: unknown,
): Promise<void> {
  try {
    await fetch(`${SUPABASE_FUNCTIONS_URL}/log-error`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        level,
        error_message: message,
        stack_trace: error?.stack,
        context: { category, ...(typeof context === 'object' ? context : { data: context }) },
        app_version: APP_VERSION,
        platform: (context as ErrorContext)?.platform ?? 'web',
      }),
    });
  } catch {
    // Ciche zakończenie — nie logujemy błędu logowania
  }
}
```

---

## 8. SortControls — wielokrotnego użytku kontrolki sortowania

```tsx
/*
 * File:       SortControls.tsx
 * Path:       packages/web/src/components/common/SortControls.tsx
 * Exports:    SortControls, useSortPreference
 * Depends on: react, react-i18next, shared/services/supabaseClient
 * Purpose:    Kontrolki sortowania listy — zapisuje preferencję w profilu użytkownika
 */
import { useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';

export type SortOption = {
  id: string;
  labelKey: string;    // klucz i18n
  icon?: string;
};

interface SortControlsProps {
  options: SortOption[];
  activeId: string;
  onChange: (id: string) => void;
  className?: string;
}

export function SortControls({ options, activeId, onChange, className }: SortControlsProps) {
  const { t } = useTranslation();

  return (
    <div
      className={['flex items-center gap-2 overflow-x-auto pb-1', className].filter(Boolean).join(' ')}
      role="group"
      aria-label={t('common.sort_label')}
    >
      <span className="text-xs text-gray-500 flex-shrink-0">{t('common.sort_label')}:</span>
      {options.map(opt => (
        <button
          key={opt.id}
          onClick={() => onChange(opt.id)}
          aria-pressed={activeId === opt.id}
          className={[
            'flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-medium border transition-all',
            activeId === opt.id
              ? 'bg-primary-500 text-white border-primary-500'
              : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300',
          ].join(' ')}
        >
          {opt.icon && <span className="mr-1">{opt.icon}</span>}
          {t(opt.labelKey)}
        </button>
      ))}
    </div>
  );
}

// Hook — zapamiętuje wybraną opcję sortowania w localStorage
export function useSortPreference(key: string, defaultId: string) {
  const storageKey = `sort_pref_${key}`;
  const [activeId, setActiveId] = useState<string>(
    () => localStorage.getItem(storageKey) ?? defaultId
  );

  const setSort = useCallback((id: string) => {
    setActiveId(id);
    localStorage.setItem(storageKey, id);
  }, [storageKey]);

  return { activeId, setSort };
}

// Przykład użycia dla listy kontaktów:
// const CONTACT_SORT_OPTIONS: SortOption[] = [
//   { id: 'alpha',    labelKey: 'contacts.sort.alpha',    icon: '🔤' },
//   { id: 'activity', labelKey: 'contacts.sort.activity', icon: '🕐' },
//   { id: 'type',     labelKey: 'contacts.sort.type',     icon: '🏷️' },
//   { id: 'unread',   labelKey: 'contacts.sort.unread',   icon: '🔵' },
// ];
```

---

## 9. ReminderModal — dodawanie przypomnień

```tsx
/*
 * File:       ReminderModal.tsx
 * Path:       packages/web/src/components/contacts/ReminderModal.tsx
 * Exports:    ReminderModal
 * Depends on: react, react-i18next, ./ClearableInput, ./LoadingButton
 * Purpose:    Modal do dodawania przypomnień do kontaktu lub globalnych
 */
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ClearableInput } from '../common/ClearableInput';
import { LoadingButton } from '../common/LoadingButton';

interface ReminderModalProps {
  isOpen: boolean;
  contactName?: string;     // gdy null = globalne przypomnienie
  onSave: (data: { title: string; remindAt: Date }) => Promise<void>;
  onClose: () => void;
}

export function ReminderModal({ isOpen, contactName, onSave, onClose }: ReminderModalProps) {
  const { t } = useTranslation();
  const [title, setTitle] = useState('');
  const [dateTimeValue, setDateTimeValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleSave = async () => {
    if (!title.trim()) { setError(t('reminders.error.title_required')); return; }
    if (!dateTimeValue) { setError(t('reminders.error.date_required')); return; }
    const remindAt = new Date(dateTimeValue);
    if (remindAt <= new Date()) { setError(t('reminders.error.date_past')); return; }

    setIsLoading(true);
    try {
      await onSave({ title: title.trim(), remindAt });
      setTitle('');
      setDateTimeValue('');
      onClose();
    } catch {
      setError(t('common.error_generic'));
    } finally {
      setIsLoading(false);
    }
  };

  // Minimalny czas w input datetime-local = teraz + 1 minuta
  const minDateTime = new Date(Date.now() + 60_000).toISOString().slice(0, 16);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} aria-hidden="true" />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <h2 className="text-lg font-bold mb-1">🔔 {t('reminders.modal.title')}</h2>
        {contactName && (
          <p className="text-sm text-gray-500 mb-4">{t('reminders.modal.for_contact', { name: contactName })}</p>
        )}

        <div className="flex flex-col gap-4">
          <ClearableInput
            label={t('reminders.modal.title_label')}
            value={title}
            onChange={setTitle}
            onClear={() => setTitle('')}
            placeholder={t('reminders.modal.title_placeholder')}
            maxLength={200}
            required
          />

          <div className="flex flex-col gap-1">
            <label className="text-sm font-medium text-gray-700">{t('reminders.modal.date_label')} *</label>
            <input
              type="datetime-local"
              value={dateTimeValue}
              min={minDateTime}
              onChange={e => setDateTimeValue(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-primary-500 outline-none"
            />
          </div>

          {error && <p className="text-xs text-danger-500" role="alert">{error}</p>}
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <button onClick={onClose} className="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50">
            {t('common.cancel')}
          </button>
          <LoadingButton isLoading={isLoading} onClick={handleSave} loadingText={t('common.saving')}>
            {t('reminders.modal.save')}
          </LoadingButton>
        </div>
      </div>
    </div>
  );
}
```

---

## 10. ModalPortal — montuje modal poza drzewem komponentów

```tsx
/*
 * File:       ModalPortal.tsx
 * Path:       packages/web/src/components/common/ModalPortal.tsx
 * Exports:    ModalPortal
 * Depends on: react, react-dom
 * Purpose:    Portal dla modali — renderuje w #modal-root poza głównym drzewem (brak problemów z z-index)
 */
import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';

interface ModalPortalProps {
  children: React.ReactNode;
  containerId?: string;
}

export function ModalPortal({ children, containerId = 'modal-root' }: ModalPortalProps) {
  const containerRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    let el = document.getElementById(containerId);
    if (!el) {
      el = document.createElement('div');
      el.id = containerId;
      document.body.appendChild(el);
    }
    containerRef.current = el;
    return () => {
      // Nie usuwamy kontenera — może mieć wiele portalów jednocześnie
    };
  }, [containerId]);

  if (!containerRef.current) return null;
  return createPortal(children, containerRef.current);
}

// Użycie — w index.html dodaj: <div id="modal-root"></div>
// Następnie opakuj każdy modal:
// <ModalPortal><ConfirmDialog ... /></ModalPortal>
```

---

## 11. Supabase CORS helper dla Edge Functions

```typescript
/*
 * File:       cors.ts
 * Path:       supabase/functions/_shared/cors.ts
 * Exports:    corsHeaders, handleCorsPreflightOrNull
 * Depends on: (none)
 * Purpose:    Wspólny helper CORS dla wszystkich Edge Functions — importowany w każdej funkcji
 */

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** Jeśli request to OPTIONS preflight — zwróć Response od razu. W przeciwnym razie null. */
export function handleCorsPreflightOrNull(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }
  return null;
}

/** Wrapper — owija Response w CORS headers */
export function corsResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/** Wrapper dla błędów */
export function corsError(message: string, status = 500): Response {
  return corsResponse({ ok: false, error: message }, status);
}
```

---

## 12. DevPanel — panel deweloperski (tylko IS_DEV)

```tsx
/*
 * File:       DevPanel.tsx
 * Path:       packages/web/src/components/system/DevPanel.tsx
 * Exports:    DevPanel
 * Depends on: react, shared/constants
 * Purpose:    Floating panel DEV-only z statusem sync, AI, limitów i przyciskami symulacji
 */
import { useState } from 'react';
import { IS_DEV, APP_VERSION } from 'shared/constants';

// Ten komponent NIE renderuje się w produkcji
export function DevPanel() {
  if (!IS_DEV) return null;

  const [isOpen, setIsOpen] = useState(false);
  const [isOffline, setIsOffline] = useState(
    () => localStorage.getItem('__simulate_offline') === 'true'
  );

  const toggleOffline = () => {
    const next = !isOffline;
    setIsOffline(next);
    localStorage.setItem('__simulate_offline', String(next));
    window.dispatchEvent(new Event(next ? 'offline' : 'online'));
  };

  const resetLimits = () => {
    localStorage.removeItem('daily_hints_used');
    localStorage.removeItem('weekly_analysis_used');
    alert('Limity zresetowane — odśwież stronę');
  };

  const clearIndexedDB = async () => {
    const dbs = await indexedDB.databases?.() ?? [];
    for (const db of dbs) {
      if (db.name) indexedDB.deleteDatabase(db.name);
    }
    alert('IndexedDB wyczyszczone — odśwież stronę');
  };

  return (
    <div className="fixed bottom-4 right-4 z-[9999]">
      <button
        onClick={() => setIsOpen(v => !v)}
        className="w-10 h-10 rounded-full bg-gray-900 text-white text-xs font-bold shadow-lg"
        title="DEV panel"
      >
        DEV
      </button>

      {isOpen && (
        <div className="absolute bottom-12 right-0 w-64 bg-gray-900 text-white rounded-xl shadow-2xl p-4 text-xs">
          <div className="font-bold mb-3 text-yellow-400">🛠 DEV PANEL · v{APP_VERSION}</div>

          <div className="flex flex-col gap-2">
            <div className="flex justify-between">
              <span>Offline simulation</span>
              <button onClick={toggleOffline} className={`px-2 py-0.5 rounded text-xs font-bold ${isOffline ? 'bg-red-500' : 'bg-green-600'}`}>
                {isOffline ? 'OFFLINE' : 'ONLINE'}
              </button>
            </div>

            <button onClick={resetLimits} className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded text-left">
              🔄 Resetuj limity AI
            </button>

            <button onClick={clearIndexedDB} className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded text-left">
              🗑️ Wyczyść IndexedDB
            </button>

            <button
              onClick={() => localStorage.setItem('__simulate_ai_429', 'true')}
              className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded text-left"
            >
              ⚠️ Symuluj Gemini 429
            </button>

            <button
              onClick={() => {
                localStorage.removeItem('__simulate_offline');
                localStorage.removeItem('__simulate_ai_429');
                localStorage.removeItem('__simulate_sync_error');
                alert('Flagi symulacji wyczyszczone');
              }}
              className="bg-red-900 hover:bg-red-800 px-3 py-1.5 rounded text-left"
            >
              ✕ Wyczyść wszystkie flagi
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```
