# 사용법

## 등록

```ts
import { registerFont } from "@7l/fontlib";

registerFont(notoSans);
registerFont(notoSansBold);
registerFont(pretendard, { family: "폰트이름", weight: 500 });
```

이름과 굵기, 기울임은 폰트에서 알아서 읽어요. 두번째 arg로 직접 지정할 수 있어요.

## 렌더링

```tsx
import { Text } from "@7l/fontlib";

<Text
	text="ㅎㅇ"
	font="Noto Sans KR"
	fontWeight="bold"
	textSize={18}
	textColor={Color3.fromRGB(255, 255, 255)}
	textWrapped
	size={UDim2.fromOffset(300, 60)}
/>;
```

## fallback

```tsx
import { FontProvider } from "@7l/fontlib";

<FontProvider defaults={{ font: "Noto Sans KR", fallbackFonts: ["Twemoji"], textSize: 14 }}>
	<App />
</FontProvider>;
```

FontProvider은 선택사항이고 defaults에 기본으로 쓸 폰트, fallback, 크기 등을 넣을 수 있어요.
