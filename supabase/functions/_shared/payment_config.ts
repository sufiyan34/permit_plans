/**
 * WorkBridge server-side payment configuration.
 * Import this file ONLY from Supabase Edge Functions (Deno).
 * Never import it into Flutter/Dart or expose its values to the client.
 */

export type PaymentMode = "mock" | "sandbox" | "live";
export type CollectionProvider = "none" | "dlocal";
export type PayoutProvider = "none" | "dlocal" | "payoneer";

function readEnv(name: string, fallback = ""): string {
  return (Deno.env.get(name) ?? fallback).trim();
}

function parseBoolean(value: string, fallback = false): boolean {
  if (!value) return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

function parseMode(value: string): PaymentMode {
  if (value === "mock" || value === "sandbox" || value === "live") {
    return value;
  }
  throw new Error(
    "Invalid PAYMENT_MODE. Use mock, sandbox, or live.",
  );
}

function parseCollectionProvider(value: string): CollectionProvider {
  if (value === "none" || value === "dlocal") return value;
  throw new Error("Invalid PAYMENT_COLLECTION_PROVIDER.");
}

function parsePayoutProvider(value: string): PayoutProvider {
  if (value === "none" || value === "dlocal" || value === "payoneer") {
    return value;
  }
  throw new Error("Invalid PAYMENT_PAYOUT_PROVIDER.");
}

export interface WorkBridgePaymentConfig {
  mode: PaymentMode;
  collectionProvider: CollectionProvider;
  payoutProvider: PayoutProvider;
  commissionBps: number;
  defaultCurrency: string;
  displayCurrencies: string[];
  liveEnabled: boolean;
  dlocal: {
    environment: string;
    apiBaseUrl: string;
    apiKey: string;
    apiSecret: string;
    platformAccountId: string;
    webhookSecret: string;
  };
  payoneer: {
    environment: string;
    apiBaseUrl: string;
    clientId: string;
    clientSecret: string;
    programId: string;
    webhookSecret: string;
  };
}

export function getPaymentConfig(): WorkBridgePaymentConfig {
  const mode = parseMode(readEnv("PAYMENT_MODE", "mock"));
  const collectionProvider = parseCollectionProvider(
    readEnv("PAYMENT_COLLECTION_PROVIDER", "none"),
  );
  const payoutProvider = parsePayoutProvider(
    readEnv("PAYMENT_PAYOUT_PROVIDER", "none"),
  );

  const commissionBps = Number.parseInt(
    readEnv("PLATFORM_COMMISSION_BPS", "500"),
    10,
  );
  if (!Number.isInteger(commissionBps) || commissionBps < 0 || commissionBps > 10000) {
    throw new Error("PLATFORM_COMMISSION_BPS must be an integer from 0 to 10000.");
  }

  const config: WorkBridgePaymentConfig = {
    mode,
    collectionProvider,
    payoutProvider,
    commissionBps,
    defaultCurrency: readEnv("PAYMENT_DEFAULT_CURRENCY", "USD").toUpperCase(),
    displayCurrencies: readEnv("PAYMENT_DISPLAY_CURRENCIES", "USD,EUR,GBP,PKR")
      .split(",")
      .map((value) => value.trim().toUpperCase())
      .filter(Boolean),
    liveEnabled: parseBoolean(readEnv("PAYMENT_LIVE_ENABLED", "false")),
    dlocal: {
      environment: readEnv("DLOCAL_ENV", "sandbox"),
      apiBaseUrl: readEnv("DLOCAL_API_BASE_URL"),
      apiKey: readEnv("DLOCAL_API_KEY"),
      apiSecret: readEnv("DLOCAL_API_SECRET"),
      platformAccountId: readEnv("DLOCAL_PLATFORM_ACCOUNT_ID"),
      webhookSecret: readEnv("DLOCAL_WEBHOOK_SECRET"),
    },
    payoneer: {
      environment: readEnv("PAYONEER_ENV", "sandbox"),
      apiBaseUrl: readEnv("PAYONEER_API_BASE_URL"),
      clientId: readEnv("PAYONEER_CLIENT_ID"),
      clientSecret: readEnv("PAYONEER_CLIENT_SECRET"),
      programId: readEnv("PAYONEER_PROGRAM_ID"),
      webhookSecret: readEnv("PAYONEER_WEBHOOK_SECRET"),
    },
  };

  // Live charging/payout is deliberately fail-closed.
  if (config.mode === "live") {
    if (!config.liveEnabled) {
      throw new Error("Live payments are disabled. Set PAYMENT_LIVE_ENABLED=true only after approvals and production checks.");
    }
    if (config.collectionProvider === "none") {
      throw new Error("A live collection provider has not been configured.");
    }
    if (config.collectionProvider === "dlocal" &&
      (!config.dlocal.apiBaseUrl || !config.dlocal.apiKey || !config.dlocal.apiSecret || !config.dlocal.webhookSecret)) {
      throw new Error("dLocal live credentials are incomplete.");
    }
    if (config.payoutProvider === "payoneer" &&
      (!config.payoneer.apiBaseUrl || !config.payoneer.clientId || !config.payoneer.clientSecret || !config.payoneer.webhookSecret)) {
      throw new Error("Payoneer live credentials are incomplete.");
    }
  }

  return config;
}
