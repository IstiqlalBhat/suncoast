import * as logger from "firebase-functions/logger";

export function logFunctionError(
  functionName: string,
  error: unknown,
  context: Record<string, unknown> = {}
): void {
  if (error instanceof Error) {
    logger.error(`${functionName} failed`, {
      ...context,
      errorMessage: error.message,
      stack: error.stack,
    });
    return;
  }

  logger.error(`${functionName} failed`, {
    ...context,
    error,
  });
}
