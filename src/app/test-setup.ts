// Node's experimental Web Storage can shadow jsdom's storage.
// Tests use isolated in-memory browser-compatible storage, never disk storage.
class TestStorage implements Storage {
  private readonly values = new Map<string, string>();
  get length(): number {
    return this.values.size;
  }
  clear(): void {
    this.values.clear();
  }
  getItem(key: string): string | null {
    return this.values.get(String(key)) ?? null;
  }
  key(index: number): string | null {
    return Array.from(this.values.keys())[index] ?? null;
  }
  removeItem(key: string): void {
    this.values.delete(String(key));
  }
  setItem(key: string, value: string): void {
    this.values.set(String(key), String(value));
  }
}
for (const key of ['localStorage', 'sessionStorage']) {
  Object.defineProperty(globalThis, key, { configurable: true, value: new TestStorage() });
}
