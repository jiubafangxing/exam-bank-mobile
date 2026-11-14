export function prettyJson(value: Object): string {
  try {
    return JSON.stringify(value, null, 2);
  } catch (e) {
    return '';
  }
}
