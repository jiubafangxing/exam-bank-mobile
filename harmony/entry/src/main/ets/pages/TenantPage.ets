import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse, TenantMembership, TenantContextView } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct TenantPage {
  @State tenants: TenantMembership[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      const ctx: TenantContextView = await repo.tenantContext();
      this.tenants = ctx.tenants ? ctx.tenants : [];
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  async choose(tenant: TenantMembership): Promise<void> {
    try {
      const resp: LoginResponse = await repo.switchTenant(tenant.tenantId ? tenant.tenantId : '');
      if (!resp.token || !resp.user) throw new Error('切换失败');
      await SessionStore.save(resp.token, JSON.stringify(resp.user));
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  build() {
    Column({ space: 10 }) {
      Text('选择机构').fontSize(20).fontWeight(FontWeight.Bold).width('100%').padding(16)
      Text('当前账号属于多个机构，请选择要进入的机构').fontSize(14).fontColor(Tokens.TEXT_SECONDARY).width('100%').padding({ left: 16, right: 16 })

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.tenants, (tenant: TenantMembership) => {
              CardContainer() {
                Column({ space: 4 }) {
                  Text(tenant.tenantName ? tenant.tenantName : '机构').fontSize(16).fontWeight(FontWeight.Medium)
                  Text(tenant.tenantCode ? tenant.tenantCode : '').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
              .onClick(() => { this.choose(tenant); })
            }, (tenant: TenantMembership, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
