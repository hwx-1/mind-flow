import { LocationSnapshot } from './LocationUtil';

export class LocationSelectionStore {
  private static hasPending: boolean = false;
  private static pending: LocationSnapshot | null = null;

  static set(location: LocationSnapshot | null): void {
    LocationSelectionStore.pending = location;
    LocationSelectionStore.hasPending = true;
  }

  static take(): LocationSnapshot | null | undefined {
    if (!LocationSelectionStore.hasPending) {
      return undefined;
    }
    LocationSelectionStore.hasPending = false;
    return LocationSelectionStore.pending;
  }
}
