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
    .borderRadius(16)
  }
}

@Component
export struct TagPill {
  label: string = '';
  fg: string = Tokens.PRIMARY;
  bg: string = Tokens.PRIMARY_SOFT;

  build() {
    Text(this.label)
      .fontSize(11)
      .fontColor(this.fg)
      .backgroundColor(this.bg)
      .borderRadius(999)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
  }
}

@Component
export struct EmptyView {
  text: string = '暂无数据';

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
  message: string = '';

  build() {
    Text(this.message)
      .fontSize(13)
      .fontColor(Tokens.DANGER)
      .width('100%')
      .padding(14)
      .backgroundColor(Tokens.DANGER_SOFT)
      .borderRadius(12)
  }
}

@Component
export struct PrimaryButton {
  label: string = '';
  loading: boolean = false;
  isEnabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Button(this.loading ? '处理中…' : this.label)
      .width('100%')
      .height(48)
      .borderRadius(999)
      .fontSize(16)
      .backgroundColor(this.isEnabled && !this.loading ? Tokens.PRIMARY : '#9DBDD9')
      .enabled(this.isEnabled && !this.loading)
      .onClick(() => this.onTap())
  }
}

@Component
export struct KeyValueRow {
  label: string = '';
  value: string = '';

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
export struct SectionTitle {
  title: string = '';

  build() {
    Text(this.title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(Tokens.TEXT_PRIMARY)
      .width('100%')
      .padding({ top: 18, bottom: 8 })
  }
}

@Component
export struct DividerLine {
  build() {
    Divider().color(Tokens.BORDER).strokeWidth(1)
  }
}
