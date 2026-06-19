import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { Const } from '../constants/Const';

export interface LocationSnapshot {
  latitude: number;
  longitude: number;
  label: string;
  address: string;
  distance?: number;
  source?: string;
}

interface AmapPoi {
  name?: string;
  address?: string | string[];
  location?: string;
  distance?: string;
  pname?: string;
  cityname?: string;
  adname?: string;
}

interface AmapAroundResp {
  status?: string;
  info?: string;
  pois?: AmapPoi[];
}

export class LocationUtil {
  private static readonly PERMISSIONS: Array<Permissions> = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION'
  ];

  static async current(ctx: common.UIAbilityContext): Promise<LocationSnapshot> {
    await LocationUtil.ensurePermission(ctx);
    if (!geoLocationManager.isLocationEnabled()) {
      throw new Error('location service disabled');
    }
    const location = await LocationUtil.getCurrentLocation();
    return LocationUtil.toSnapshot(location);
  }

  static async searchNearby(center: LocationSnapshot, keyword: string = ''): Promise<LocationSnapshot[]> {
    if (Const.AMAP_WEB_KEY.length === 0) {
      return [];
    }

    const radius = Const.AMAP_LOCATION_RADIUS;
    const params: string[] = [
      `key=${encodeURIComponent(Const.AMAP_WEB_KEY)}`,
      `location=${encodeURIComponent(`${center.longitude},${center.latitude}`)}`,
      `radius=${radius}`,
      'offset=20',
      'page=1',
      'sortrule=distance',
      'output=json'
    ];
    if (keyword.trim().length > 0) {
      params.push(`keywords=${encodeURIComponent(keyword.trim())}`);
    }

    const request = http.createHttp();
    try {
      const resp = await request.request(`https://restapi.amap.com/v3/place/around?${params.join('&')}`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000,
        usingCache: false
      });
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        throw new Error(`amap http ${resp.responseCode}`);
      }
      const text = LocationUtil.responseText(resp.result);
      const json = JSON.parse(text) as AmapAroundResp;
      if (json.status !== '1') {
        throw new Error(json.info || 'amap search failed');
      }
      return LocationUtil.parsePois(center, json.pois || []);
    } finally {
      request.destroy();
    }
  }

  static distanceMeters(a: LocationSnapshot, b: LocationSnapshot): number {
    const earthRadius = 6371000;
    const lat1 = LocationUtil.toRad(a.latitude);
    const lat2 = LocationUtil.toRad(b.latitude);
    const deltaLat = LocationUtil.toRad(b.latitude - a.latitude);
    const deltaLng = LocationUtil.toRad(b.longitude - a.longitude);
    const sinLat = Math.sin(deltaLat / 2);
    const sinLng = Math.sin(deltaLng / 2);
    const h = sinLat * sinLat + Math.cos(lat1) * Math.cos(lat2) * sinLng * sinLng;
    return 2 * earthRadius * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
  }

  private static async ensurePermission(ctx: common.UIAbilityContext): Promise<void> {
    const atManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResult =
      await atManager.requestPermissionsFromUser(ctx, LocationUtil.PERMISSIONS);
    if (!result.authResults.some((status: number) => status === 0)) {
      throw new Error('location permission denied');
    }
  }

  private static getCurrentLocation(): Promise<geoLocationManager.Location> {
    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.ACCURACY,
      scenario: geoLocationManager.LocationRequestScenario.DAILY_LIFE_SERVICE,
      maxAccuracy: 100,
      timeoutMs: 10000
    };
    return geoLocationManager.getCurrentLocation(request);
  }

  private static async toSnapshot(location: geoLocationManager.Location): Promise<LocationSnapshot> {
    const coordinate = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
    try {
      const available = geoLocationManager.isGeocoderAvailable();
      if (available) {
        const list = await geoLocationManager.getAddressesFromLocation({
          latitude: location.latitude,
          longitude: location.longitude,
          locale: 'zh',
          maxItems: 1
        });
        if (list.length > 0) {
          const address = LocationUtil.formatAddress(list[0]);
          const label = LocationUtil.formatLabel(list[0], address);
          if (label) {
            return {
              latitude: location.latitude,
              longitude: location.longitude,
              label,
              address: address || label,
              source: 'current'
            };
          }
        }
      }
    } catch (_) {}

    return {
      latitude: location.latitude,
      longitude: location.longitude,
      label: `当前位置 ${coordinate}`,
      address: coordinate,
      source: 'current'
    };
  }

  private static parsePois(center: LocationSnapshot, pois: AmapPoi[]): LocationSnapshot[] {
    const list: LocationSnapshot[] = [];
    pois.forEach((poi: AmapPoi) => {
      const location = poi.location || '';
      const pair = location.split(',');
      if (pair.length !== 2) {
        return;
      }
      const longitude = Number(pair[0]);
      const latitude = Number(pair[1]);
      if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return;
      }
      const address = LocationUtil.poiAddress(poi);
      const item: LocationSnapshot = {
        latitude,
        longitude,
        label: poi.name || address || '附近位置',
        address,
        source: 'amap'
      };
      item.distance = poi.distance ? Number(poi.distance) : LocationUtil.distanceMeters(center, item);
      if (item.distance <= Const.AMAP_LOCATION_RADIUS) {
        list.push(item);
      }
    });
    return list;
  }

  private static poiAddress(poi: AmapPoi): string {
    const parts: string[] = [];
    LocationUtil.pushPart(parts, poi.pname);
    LocationUtil.pushPart(parts, poi.cityname);
    LocationUtil.pushPart(parts, poi.adname);
    if (Array.isArray(poi.address)) {
      LocationUtil.pushPart(parts, poi.address.join(''));
    } else {
      LocationUtil.pushPart(parts, poi.address);
    }
    return parts.join('');
  }

  private static responseText(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      return util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(result));
    }
    return JSON.stringify(result);
  }

  private static toRad(value: number): number {
    return value * Math.PI / 180;
  }

  private static pushPart(parts: string[], part?: string): void {
    const text = (part || '').trim();
    if (text.length > 0 && !parts.includes(text)) {
      parts.push(text);
    }
  }

  private static formatAddress(address: geoLocationManager.GeoAddress): string {
    const parts: string[] = [];
    LocationUtil.pushPart(parts, address.administrativeArea);
    LocationUtil.pushPart(parts, address.locality);
    LocationUtil.pushPart(parts, address.subLocality);
    LocationUtil.pushPart(parts, address.roadName);
    LocationUtil.pushPart(parts, address.subRoadName);
    LocationUtil.pushPart(parts, address.premises);
    LocationUtil.pushPart(parts, address.placeName);
    return parts.join('');
  }

  private static formatLabel(address: geoLocationManager.GeoAddress, fullAddress: string): string {
    const candidates: Array<string | undefined> = [
      address.placeName,
      address.premises,
      address.subRoadName,
      address.roadName,
      address.subLocality,
      address.locality,
      address.administrativeArea,
      fullAddress
    ];
    for (let i = 0; i < candidates.length; i++) {
      const text = (candidates[i] || '').trim();
      if (text.length > 0) {
        return text;
      }
    }
    return '';
  }
}
