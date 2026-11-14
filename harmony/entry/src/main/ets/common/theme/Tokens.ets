export interface ColorPair {
  fg: string;
  bg: string;
}

/** 与 shared/design/tokens.json 一一对应。 */
export class Tokens {
  static readonly PRIMARY: string = '#1F5F99';
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
  static readonly BORDER_STRONG: string = '#CBD5E1';
  static readonly SUCCESS: string = '#15803D';
  static readonly SUCCESS_SOFT: string = '#ECFDF5';
  static readonly WARNING: string = '#B45309';
  static readonly WARNING_SOFT: string = '#FFFBEB';
  static readonly DANGER: string = '#C0392B';
  static readonly DANGER_SOFT: string = '#FDF2F2';

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
