<div align="center">

<img src="assets/logo.png" alt="fontlib" width="320">

로블록스 ttf 라이브러리

</div>

---

## 설치

```sh
npm i @7l/fontlib
```

## 예시

```tsx
import { registerFont, Text } from "@7l/fontlib";
import notoSans from "./fonts/noto-sans"; // buffer

registerFont(notoSans);

<Text text="안녕하세요" font="Noto Sans KR" textSize={18} size={UDim2.fromOffset(300, 40)} />;
```

자세한건 [docs/usage.md](docs/usage.md)
