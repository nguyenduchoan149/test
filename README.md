# Calculator — HTML → Node → COBOL

Bài tập nối máy tính trên web với chương trình COBOL qua Node.js.

Khi bấm `=` trên UI, biểu thức **raw** được gửi lên Node. Node chạy `MAIN.exe`, COBOL in log ra stdout, Node in lại trên console. Kết quả **chưa** trả về giao diện.

## Luồng chạy

```text
[Browser] calculator.html
    |  POST /api/calculate  { raw: "(1+2)*sqrt(9)^2" }
    v
[Node]    server.js
    |  spawn MAIN.exe  +  ghi raw vào stdin
    |  COB_LIBRARY_PATH = bin/
    v
[COBOL]   MAIN.exe
    |  CALL CALCULATOR.dll
    |       CALL LOGIC01.dll … LOGIC05.dll
    |  DISPLAY …  → stdout
    v
[Node]    console.log(stdout)
```

## Ý nghĩa từng phần

| Phần | Vai trò |
|------|---------|
| `public/calculator.html` | UI máy tính (`+ − × ÷ ( ) √ x²`). Gửi raw, không validate. |
| `server.js` | API + gọi COBOL. Log stdout ra terminal. |
| `src/main/MAIN.cbl` | Cổng vào COBOL: đọc stdin → gọi module → in stdout. |
| `src/utils/CALCULATOR.cbl` | **Chỗ điền logic** (parse / tính toán). Hiện đang mock. |
| `src/utils/LOGIC01.cbl` … `LOGIC05.cbl` | Module con (hiện mỗi file chỉ `DISPLAY` log). |
| `copybook/DEMOMSG.cpy` | Vùng dữ liệu dùng chung khi `CALL`. |

## Cấu trúc thư mục

```text
calculator/
├── public/calculator.html     # UI
├── server.js                  # Node bridge
├── copybook/DEMOMSG.cpy
├── src/
│   ├── main/MAIN.cbl          # → bin/MAIN.exe
│   └── utils/
│       ├── CALCULATOR.cbl     # → bin/CALCULATOR.dll
│       └── LOGIC01.cbl … 05   # → bin/LOGIC*.dll
├── bin/                       # output sau khi build (tự sinh)
└── scripts/
    ├── build-local.ps1
    └── test-local.ps1
```

## Cách build

Cần [GnuCOBOL](https://gnucobol.sourceforge.io/) (`cobc` có trong `PATH`).

```powershell
cd mainframe-cobol\calculator
.\scripts\build-local.ps1
```

Script sẽ:

1. Xóa output cũ trong `bin/`
2. Compile mọi `.cbl` trong `src/utils/` → **`.dll`** (`cobc -m`)
3. Compile mọi `.cbl` trong `src/main/` → **`.exe`** (`cobc -x`)

Quy tắc đơn giản:

- File trong `src/main/` = chương trình chạy được (exe)
- File trong `src/utils/` = module được `CALL` (dll)

Sau build, `bin/` thường có:

```text
MAIN.exe
CALCULATOR.dll
LOGIC01.dll … LOGIC05.dll
```

Kiểm tra nhanh:

```powershell
.\scripts\test-local.ps1
```

## Cách chạy

```powershell
cd mainframe-cobol\calculator
.\scripts\build-local.ps1
node server.js
```

Mở trình duyệt: http://localhost:3456/calculator.html  

Xem log COBOL trên **terminal đang chạy Node** (không trên trang web).

## Ghi chú

- Sửa logic: sửa `src/utils/CALCULATOR.cbl` (và `LOGIC*` nếu cần), rồi build lại.
- Thêm module dll: thả `.cbl` vào `src/utils/`, `CALL` từ `CALCULATOR`, build lại.
- Thêm chương trình exe: thả `.cbl` vào `src/main/`, build lại.
