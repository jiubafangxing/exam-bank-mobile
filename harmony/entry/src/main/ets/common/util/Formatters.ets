export class Formatters {
  private static pad(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  static epochToDateTime(millis?: string): string {
    if (!millis) return '';
    const ms = Number(millis);
    if (!ms || ms <= 0) return '';
    const d = new Date(ms);
    return '' + d.getFullYear() + '-' + Formatters.pad(d.getMonth() + 1) + '-' + Formatters.pad(d.getDate())
      + ' ' + Formatters.pad(d.getHours()) + ':' + Formatters.pad(d.getMinutes());
  }

  static countdown(remainingSeconds: number): string {
    const total = remainingSeconds > 0 ? remainingSeconds : 0;
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    const s = total % 60;
    return h > 0
      ? Formatters.pad(h) + ':' + Formatters.pad(m) + ':' + Formatters.pad(s)
      : Formatters.pad(m) + ':' + Formatters.pad(s);
  }

  static durationText(seconds?: number): string {
    const s = seconds ? seconds : 0;
    if (s <= 0) return '不限时';
    const m = Math.floor(s / 60);
    return m >= 60 ? Math.floor(m / 60) + '小时' + (m % 60) + '分' : m + '分钟';
  }

  static scoreText(value?: number): string {
    if (value === undefined || value === null) return '-';
    return value % 1 === 0 ? '' + Math.trunc(value) : value.toFixed(1);
  }

  static questionTypeLabel(type?: string): string {
    switch ((type ? type : '').toUpperCase()) {
      case 'SINGLE': return '单选题';
      case 'MULTIPLE': return '多选题';
      case 'JUDGE': return '判断题';
      case 'FILL': return '填空题';
      case 'ESSAY': return '问答题';
      default: return type ? type : '';
    }
  }

  static attemptStatusLabel(status?: string): string {
    switch ((status ? status : '').toUpperCase()) {
      case 'ASSIGNED': return '待开始';
      case 'STARTED':
      case 'IN_PROGRESS': return '进行中';
      case 'SUBMITTED': return '已交卷';
      case 'GRADING': return '阅卷中';
      case 'GRADED': return '已出分';
      case 'EXPIRED': return '已过期';
      case 'ABSENT': return '缺考';
      default: return status ? status : '';
    }
  }

  static orderStatusLabel(status?: string): string {
    switch ((status ? status : '').toUpperCase()) {
      case 'UNPAID':
      case 'PENDING': return '待支付';
      case 'PAID':
      case 'SUCCESS': return '已支付';
      case 'CANCELLED':
      case 'CANCELED': return '已取消';
      case 'REFUNDED': return '已退款';
      default: return status ? status : '';
    }
  }

  static greeting(): string {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 11) return '早上好';
    if (hour >= 11 && hour < 13) return '中午好';
    if (hour >= 13 && hour < 18) return '下午好';
    if (hour >= 18 && hour < 23) return '晚上好';
    return '你好';
  }
}
