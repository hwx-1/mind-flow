export interface ProfileStatusStyle {
  color: string;
  tint: string;
}

export class ProfileStatusUtil {
  static styleOf(status?: string): ProfileStatusStyle {
    switch (status) {
      case '忙碌':
        return { color: '#FFE0B87F', tint: '#FFFFF4D6' };
      case '离开':
        return { color: '#FF8A7D6E', tint: '#FFF3ECE1' };
      case '勿扰':
        return { color: '#FFC0573F', tint: '#FFF6E4DB' };
      case '隐身':
        return { color: '#FF8A7158', tint: '#FFF0E6D8' };
      case '在线':
      default:
        return { color: '#FF7D9268', tint: '#FFEAF0E4' };
    }
  }
}
