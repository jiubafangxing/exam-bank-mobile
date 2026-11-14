import { Tokens } from '../common/theme/Tokens';

@Component
export struct CardContainer {
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Tokens.SURFACE)
    .borderRadius(Tokens.RADIUS_LG + 2)
    .border({ width: 1, color: Tokens.BORDER_SOFT })
    .shadow({
      radius: Tokens.SHADOW_CARD_RADIUS,
      color: Tokens.SHADOW_CARD_COLOR,
      offsetX: 0,
      offsetY: Tokens.SHADOW_CARD_OFFSET_Y
    })
  }
}

@Component
export struct TagPill {
  @Prop label: string = '';
  @Prop fg: string = Tokens.PRIMARY;
  @Prop bg: string = Tokens.PRIMARY_SOFT;

  build() {
    Text(this.label)
      .fontSize(11)
      .fontColor(this.fg)
      .backgroundColor(this.bg)
      .borderRadius(Tokens.RADIUS_PILL)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
  }
}

@Component
export struct EmptyView {
  @Prop text: string = '暂无数据';

  build() {
    Text(this.text)
      .fontSize(14)
      .fontColor(Tokens.TEXT_SECONDARY)
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 48, bottom: 48 })
  }
}

@Component
export struct LoadingView {
  build() {
    Row() {
      LoadingProgress().width(28).height(28).color(Tokens.PRIMARY)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 48, bottom: 48 })
  }
}

@Component
export struct ErrorBanner {
  @Prop message: string = '';

  build() {
    Text(this.message)
      .fontSize(13)
      .fontColor(Tokens.DANGER)
      .width('100%')
      .padding(14)
      .backgroundColor(Tokens.DANGER_SOFT)
      .borderRadius(Tokens.RADIUS_MD + 2)
  }
}

@Component
export struct PrimaryButton {
  @Prop label: string = '';
  @Prop loading: boolean = false;
  @Prop isEnabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.loading ? '处理中…' : this.label)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
    }
    .width('100%')
    .height(50)
    .borderRadius(Tokens.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: this.isEnabled && !this.loading
        ? [[Tokens.GRADIENT_PRIMARY[0], 0], [Tokens.GRADIENT_PRIMARY[1], 0.55], [Tokens.GRADIENT_PRIMARY[2], 1]]
        : [[Tokens.BORDER_STRONG, 0], [Tokens.BORDER_STRONG, 1]]
    })
    .shadow({
      radius: Tokens.SHADOW_BUTTON_RADIUS,
      color: this.isEnabled && !this.loading ? Tokens.SHADOW_BUTTON_COLOR : '#00000000',
      offsetX: 0,
      offsetY: Tokens.SHADOW_BUTTON_OFFSET_Y
    })
    .opacity(this.isEnabled && !this.loading ? 1 : 0.75)
    .onClick(() => {
      if (this.isEnabled && !this.loading) this.onTap();
    })
  }
}

@Component
export struct SecondaryButton {
  @Prop label: string = '';
  @Prop isEnabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isEnabled ? Tokens.PRIMARY : Tokens.TEXT_TERTIARY)
        .maxLines(1)
    }
    .height(44)
    .borderRadius(Tokens.RADIUS_LG)
    .backgroundColor(this.isEnabled ? Tokens.PRIMARY_SOFT : Tokens.SURFACE_ALT)
    .padding({ left: 16, right: 16 })
    .opacity(this.isEnabled ? 1 : 0.8)
    .onClick(() => {
      if (this.isEnabled) this.onTap();
    })
  }
}

/** 顶部渐变 Hero，带装饰光斑。 */
@Component
export struct GradientHero {
  @Prop gradientStart: string = Tokens.PRIMARY;
  @Prop gradientEnd: string = Tokens.HERO_END;
  @BuilderParam content: () => void;

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Circle({ width: 180, height: 180 })
        .fill('#21FFFFFF')
        .offset({ x: 44, y: -56 })
      Circle({ width: 96, height: 96 })
        .fill('#14FFFFFF')
        .offset({ x: 30, y: 120 })
      Column() {
        this.content()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(20)
    }
    .width('100%')
    .borderRadius(Tokens.RADIUS_XXL)
    .clip(true)
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0], [this.gradientEnd, 1]] })
    .shadow({
      radius: Tokens.SHADOW_HERO_RADIUS,
      color: Tokens.SHADOW_HERO_COLOR,
      offsetX: 0,
      offsetY: Tokens.SHADOW_HERO_OFFSET_Y
    })
  }
}

/** 柔和底色图标块（无系统图标依赖，用首字字形保证三端可编译）。 */
@Component
export struct IconTile {
  @Prop label: string = '';
  @Prop fg: string = Tokens.PRIMARY;
  @Prop bg: string = Tokens.PRIMARY_SOFT;
  @Prop tileSize: number = 44;
  @Prop fontSize: number = 0;

  private glyph(): string {
    if (this.label.length === 0) return '·';
    return this.label.substring(0, 1);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.glyph())
        .fontSize(this.fontSize > 0 ? this.fontSize : Math.floor(this.tileSize * 0.4))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.fg)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(this.tileSize)
    .height(this.tileSize)
    .borderRadius(Math.floor(this.tileSize * 0.32))
    .linearGradient({ angle: 145, colors: [[this.bg, 0], ['#FFFFFFFF', 1]] })
  }
}

/** 4x18 渐变强调条 + 标题 + 可选操作。 */
@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop actionLabel: string = '';
  onAction: () => void = () => {};

  build() {
    Row() {
      Column()
        .width(4)
        .height(18)
        .borderRadius(4)
        .linearGradient({ angle: 180, colors: [[Tokens.PRIMARY, 0], [Tokens.ACCENT, 1]] })
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Tokens.TEXT_PRIMARY)
        .margin({ left: 8 })
      Blank()
      if (this.actionLabel.length > 0) {
        Row() {
          Text(this.actionLabel).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
          Text('›').fontSize(16).fontColor(Tokens.TEXT_TERTIARY).margin({ left: 2 })
        }
        .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .padding({ top: 20, bottom: 10 })
  }
}

@Component
export struct SectionTitle {
  @Prop title: string = '';

  build() {
    SectionHeader({ title: this.title })
  }
}

/** 柔和渐变底色的统计块。 */
@Component
export struct StatTile {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop tint: string = Tokens.PRIMARY;
  @Prop bg: string = Tokens.PRIMARY_SOFT;

  build() {
    Column({ space: 3 }) {
      Text(this.value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tint)
        .maxLines(1)
      Text(this.label)
        .fontSize(11)
        .fontColor(Tokens.TEXT_SECONDARY)
        .maxLines(1)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 6, right: 6 })
    .borderRadius(Tokens.RADIUS_LG)
    .linearGradient({ angle: 145, colors: [[this.bg, 0], ['#FFFFFFFF', 1]] })
  }
}

@Component
export struct SmallAction {
  @Prop label: string = '';
  @Prop color: string = Tokens.PRIMARY;
  @Prop bg: string = Tokens.PRIMARY_SOFT;
  onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.color)
      .backgroundColor(this.bg)
      .borderRadius(Tokens.RADIUS_PILL)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .onClick(() => this.onTap())
  }
}

/** 图标块 + 标题/副标题 + 右侧文案/箭头 的通用列表行。 */
@Component
export struct ListRow {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop trailing: string = '';
  @Prop showArrow: boolean = true;
  @Prop tileLabel: string = '';
  @Prop tileFg: string = Tokens.PRIMARY;
  @Prop tileBg: string = Tokens.PRIMARY_SOFT;
  onTap: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      if (this.tileLabel.length > 0) {
        IconTile({ label: this.tileLabel, fg: this.tileFg, bg: this.tileBg, tileSize: 34, fontSize: 14 })
      }
      Column({ space: 2 }) {
        Text(this.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
        if (this.subtitle.length > 0) {
          Text(this.subtitle).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (this.trailing.length > 0) {
        Text(this.trailing).fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
      }
      if (this.showArrow) {
        Text('›').fontSize(18).fontColor(Tokens.TEXT_TERTIARY)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .onClick(() => this.onTap())
  }
}

/** 登录/注册等认证页顶部渐变头部。 */
@Component
export struct AuthHero {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop glyph: string = '考';

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Circle({ width: 190, height: 190 }).fill('#21FFFFFF').offset({ x: 48, y: -52 })
      Circle({ width: 130, height: 130 }).fill('#14FFFFFF').offset({ x: -20, y: 120 })
      Column({ space: 6 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column().width(50).height(50).borderRadius(Tokens.RADIUS_LG).backgroundColor('#38FFFFFF')
          Text(this.glyph).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        }.width(50).height(50)
        Text(this.title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').margin({ top: 12 })
        Text(this.subtitle).fontSize(13).fontColor('#E8FFFFFF')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24, top: 48, bottom: 28 })
    }
    .width('100%')
    .borderRadius({ bottomLeft: 32, bottomRight: 32 })
    .clip(true)
    .linearGradient({
      angle: 135,
      colors: [[Tokens.GRADIENT_HERO[0], 0], [Tokens.GRADIENT_HERO[1], 1]]
    })
  }
}

@Component
export struct KeyValueRow {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row() {
      Text(this.label).fontSize(13).fontColor(Tokens.TEXT_SECONDARY).width(84)
      Text(this.value).fontSize(13).fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

@Component
export struct DividerLine {
  build() {
    Divider().color(Tokens.BORDER).strokeWidth(1)
  }
}
