export interface ColorPair {
  fg: string;
  bg: string;
}

/** 与 shared/design/tokens.json 一一对应。 */
export class Tokens {
  static readonly PRIMARY: string = '#1F5F99';
  static readonly PRIMARY_DEEP: string = '#103A5C';
  static readonly PRIMARY_DARK: string = '#16466F';
  static readonly PRIMARY_LIGHT: string = '#5AA7EA';
  static readonly PRIMARY_SOFT: string = '#E8F1FA';
  static readonly BACKGROUND: string = '#F4F6FB';
  static readonly SURFACE: string = '#FFFFFF';
  static readonly SURFACE_ALT: string = '#EEF3F8';
  static readonly TEXT_PRIMARY: string = '#1F2937';
  static readonly TEXT_SECONDARY: string = '#8A94A6';
  static readonly TEXT_TERTIARY: string = '#94A3B8';
  static readonly BORDER: string = '#E2EAF3';
  static readonly BORDER_SOFT: string = '#A6E2EAF3';
  static readonly BORDER_STRONG: string = '#CBD5E1';
  static readonly SUCCESS: string = '#15803D';
  static readonly SUCCESS_SOFT: string = '#ECFDF5';
  static readonly WARNING: string = '#B45309';
  static readonly WARNING_SOFT: string = '#FFFBEB';
  static readonly DANGER: string = '#C0392B';
  static readonly DANGER_SOFT: string = '#FDF2F2';
  static readonly INFO: string = '#6D28D9';
  static readonly INFO_SOFT: string = '#F5F3FF';
  static readonly PINK: string = '#BE185D';
  static readonly PINK_SOFT: string = '#FDF2F8';
  static readonly OVERLAY: string = '#66000000';
  static readonly WHITE: string = '#FFFFFF';

  static readonly ACCENT: string = '#2FA6A0';
  static readonly ACCENT_SOFT: string = '#E6F7F5';
  static readonly CORAL: string = '#E56B6F';
  static readonly CORAL_SOFT: string = '#FDECEE';
  static readonly VIOLET: string = '#7C5CFC';
  static readonly VIOLET_SOFT: string = '#F0EDFF';
  static readonly AMBER: string = '#F59E0B';
  static readonly AMBER_SOFT: string = '#FFF5E5';
  static readonly SKY: string = '#0EA5E9';
  static readonly SKY_SOFT: string = '#E6F6FE';
  static readonly SLATE: string = '#64748B';
  static readonly SLATE_SOFT: string = '#EEF2F7';
  static readonly ROSE: string = '#EC4899';
  static readonly ROSE_SOFT: string = '#FDECF4';
  static readonly HERO_END: string = '#4F46E5';

  // 渐变色（供 ArkUI linearGradient 逐段拼装）
  static readonly GRADIENT_PRIMARY: string[] = ['#16466F', '#1F5F99', '#2F80C8'];
  static readonly GRADIENT_HERO: string[] = ['#1F5F99', '#4F46E5'];
  static readonly GRADIENT_ACCENT: string[] = ['#1F5F99', '#2FA6A0'];
  static readonly GRADIENT_SUCCESS: string[] = ['#15803D', '#34D399'];
  static readonly GRADIENT_DANGER: string[] = ['#C0392B', '#E56B6F'];
  static readonly GRADIENT_GOLD: string[] = ['#B45309', '#F59E0B'];

  // 圆角
  static readonly RADIUS_SM: number = 8;
  static readonly RADIUS_MD: number = 12;
  static readonly RADIUS_LG: number = 16;
  static readonly RADIUS_XL: number = 20;
  static readonly RADIUS_XXL: number = 24;
  static readonly RADIUS_PILL: number = 999;

  // 阴影
  static readonly SHADOW_CARD_COLOR: string = '#140F172A';
  static readonly SHADOW_CARD_RADIUS: number = 20;
  static readonly SHADOW_CARD_OFFSET_Y: number = 6;
  static readonly SHADOW_HERO_COLOR: string = '#1F5F993D';
  static readonly SHADOW_HERO_RADIUS: number = 30;
  static readonly SHADOW_HERO_OFFSET_Y: number = 14;
  static readonly SHADOW_BUTTON_COLOR: string = '#1F5F9933';
  static readonly SHADOW_BUTTON_RADIUS: number = 14;
  static readonly SHADOW_BUTTON_OFFSET_Y: number = 8;

  static readonly ICON_PALETTE: ColorPair[] = [
    { fg: '#1F5F99', bg: '#E8F1FA' },
    { fg: '#2FA6A0', bg: '#E6F7F5' },
    { fg: '#E56B6F', bg: '#FDECEE' },
    { fg: '#7C5CFC', bg: '#F0EDFF' },
    { fg: '#F59E0B', bg: '#FFF5E5' },
    { fg: '#0EA5E9', bg: '#E6F6FE' },
    { fg: '#64748B', bg: '#EEF2F7' },
    { fg: '#EC4899', bg: '#FDECF4' }
  ];

  static palette(index: number): ColorPair {
    const total = Tokens.ICON_PALETTE.length;
    const safe = index >= 0 ? index % total : 0;
    return Tokens.ICON_PALETTE[safe];
  }

  static typeColor(type?: string): ColorPair {
    switch ((type ? type : '').toUpperCase()) {
      case 'MULTIPLE': return { fg: '#6D28D9', bg: '#F5F3FF' };
      case 'JUDGE': return { fg: '#15803D', bg: '#ECFDF5' };
      case 'FILL': return { fg: '#B45309', bg: '#FFF7ED' };
      case 'ESSAY': return { fg: '#BE185D', bg: '#FDF2F8' };
      default: return { fg: '#1F5F99', bg: '#EEF6FF' };
    }
  }
}
