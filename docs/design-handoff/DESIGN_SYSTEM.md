# Design System — แอปพนักงาน ร้านเสน่ห์ร้อยรส

> สำหรับ Claude Code: ไฟล์นี้คือ source of truth ของสี ตัวอักษร ระยะห่าง และ component
> mockup ทุกหน้า (`design/pages/*.dc.html`) เขียนเป็น inline style — **ห้าม copy style ตรงๆ**
> ให้แปลงเป็น token + Phoenix function component ตามไฟล์นี้

> **Reference implementation:** `components/components.css` + `components/index.html` (เปิดใน browser ดู component ทุกตัวทุก state)
> ชื่อ class ใน CSS = ชื่อ component ด้านล่าง (`.btn--primary` → `<.button variant={:primary}>`, `.stepper--active` → `<.stepper value={2}>`)

- Platform: มือถือ แนวตั้ง กว้างอ้างอิง **390px** (iPhone 12–15) ใช้งานด้วยนิ้วโป้งข้างเดียว
- ภาษา UI: ไทยทั้งหมด (`lang="th"`)
- Stack ที่ตั้งใจ: Phoenix LiveView + Tailwind (v4 `@theme`) + HEEx function components

---

## 1. Design tokens

### 1.1 สี (CSS variables)

```css
:root {
  /* แบรนด์ */
  --color-primary: #054C4C;        /* ปุ่มหลัก, ตัวอักษรหลัก, ชิป/แท็บที่เลือก */
  --color-primary-hover: #033636;  /* กด/hover ปุ่มหลัก */
  --color-primary-tint: #DDEBE9;   /* ป้าย "ต้องเลือก 1", หัวคอลัมน์, avatar พื้นอ่อน */
  --color-on-primary: #FFFFFF;

  /* พื้น */
  --color-bg: #FCF5E6;             /* พื้นหลังทุกหน้า, แถบล่าง */
  --color-surface: #FFFAF0;        /* การ์ด, ช่องกรอก, ชิปที่ยังไม่เลือก, โต๊ะว่าง */
  --color-surface-white: #FFFFFF;  /* การ์ดสรุป, การ์ดที่ถูกเลือก, ช่องราคา */
  --color-sand: #F1E6C4;           /* กล่องหมายเหตุ/คำแนะนำ, segment track */
  --color-photo-placeholder: #F5EBCF;

  /* เส้น */
  --color-border: #DCC489;         /* ขอบช่องกรอก, ชิป, ปุ่มรอง */
  --color-border-soft: #E6D6A6;    /* ขอบการ์ด, เส้นใต้ header */
  --color-divider: #EFE3BF;        /* เส้นคั่นแถวในการ์ด */
  --color-border-dashed: #C9AE6A;  /* ปุ่ม "+ เพิ่ม…" เส้นประ, จุดรหัสว่าง */
  --color-switch-off: #D9CBA0;

  /* ตัวอักษร / ไอคอน */
  --color-text: #054C4C;
  --color-text-muted: #4A6462;     /* คำอธิบาย, subtitle */
  --color-icon-muted: #8A8A72;     /* ลูกศร >, ปุ่ม × */
  --color-handle: #A9A27F;         /* จุดลากเรียงลำดับ */
  --color-note-text: #4A4630;      /* ตัวอักษรบนพื้น sand */
  --color-disabled: #B9B39A;       /* เมนูแถบล่างที่ไม่มีสิทธิ์ (สีเทา ไม่มีไอคอนกุญแจ) */
  --color-disabled-soft: #C9BC94;  /* ปุ่ม − ตอนค่า 0, ขีด – ในตาราง */

  /* สถานะ */
  --color-wait-bg: #F2C46B;        /* โต๊ะมีลูกค้า (พื้น) / ป้ายจำนวนบนพื้นเข้ม */
  --color-wait-border: #E0A93A;
  --color-wait-text: #3D2E0A;      /* ตัวอักษรบนโต๊ะมีลูกค้า, พื้น toast */
  --color-multi-tag-bg: #F3E9CC;   /* ป้าย "เลือกได้หลายอย่าง" */
  --color-multi-tag-text: #6B5A22;
  --color-accent-brown: #8A4B12;   /* ป้ายผู้จัดการ, หมายเหตุ, "หมดวันนี้", ปุ่มลด */
  --color-note-bg: #FBEFD6;        /* ป้ายหมายเหตุในรายการ */
  --color-minus-bg: #FFF3E0;       /* พื้นปุ่ม − ในตัวนับ */
  --color-soldout-bg: #EFE7D2;     /* แถวเมนูที่ปิดขาย */
  --color-danger: #A4432C;         /* ลบ, เอาออก */
}
```

### 1.2 Tailwind v4 (`assets/css/app.css`)

```css
@import "tailwindcss";

@theme {
  --font-sans: "IBM Plex Sans Thai", ui-sans-serif, system-ui, sans-serif;

  --color-primary: #054C4C;
  --color-primary-hover: #033636;
  --color-primary-tint: #DDEBE9;
  --color-bg: #FCF5E6;
  --color-surface: #FFFAF0;
  --color-sand: #F1E6C4;
  --color-line: #DCC489;
  --color-line-soft: #E6D6A6;
  --color-divider: #EFE3BF;
  --color-line-dashed: #C9AE6A;
  --color-muted: #4A6462;
  --color-icon: #8A8A72;
  --color-note: #4A4630;
  --color-disabled: #B9B39A;
  --color-disabled-soft: #C9BC94;
  --color-wait: #F2C46B;
  --color-wait-line: #E0A93A;
  --color-wait-ink: #3D2E0A;
  --color-multi: #F3E9CC;
  --color-multi-ink: #6B5A22;
  --color-brown: #8A4B12;
  --color-note-bg: #FBEFD6;
  --color-minus: #FFF3E0;
  --color-soldout: #EFE7D2;
  --color-danger: #A4432C;

  --radius-sm: 10px;
  --radius-md: 12px;
  --radius-lg: 14px;
  --radius-xl: 16px;
  --radius-2xl: 18px;
}
```

### 1.3 ตัวอักษร

Font: **IBM Plex Sans Thai** น้ำหนัก 400 / 500 / 600 / 700 (Google Fonts)
ใบครัว/ใบเสร็จ ใช้ฟอนต์เดียวกัน (ถ้าเครื่องพิมพ์ไม่รองรับ ใช้ฟอนต์ไทยของเครื่องพิมพ์)

| Token | size / weight | ใช้ที่ |
|---|---|---|
| `title-xl` | 24 / 700 | ชื่อหน้า "โต๊ะ 1", "กลับบ้าน · ก3" |
| `title-lg` | 22 / 700 | หน้าแรก "รับออเดอร์", "ตั้งค่า" |
| `title-md` | 19–20 / 700 | หัวหน้าย่อย (เพิ่มเมนู, เพิ่มพนักงาน) |
| `section` | 18 / 700 | หัวกลุ่มในหน้า (น้ำชง) |
| `item` | 16 / 700 | ชื่อเมนูในรายการ, ชื่อในการ์ด |
| `chip` | 15 / 600 (เลือก) · 400–500 (ไม่เลือก) | ชิป, แท็บ |
| `body` | 14 / 400 | คำอธิบาย, ตัวเลือกที่เลือกไว้ |
| `caption` | 13 / 400–600 | subtitle, หัวคอลัมน์ |
| `badge` | 12–12.5 / 600–700 | ป้าย, ตัวเลขจำนวน |
| `price-xl` | 28–32 / 700 | ยอดรวม |

### 1.4 ระยะ / ขนาด

- Page padding แนวนอน **16px**
- Gap ที่ใช้: 4, 6, 8, 10, 12, 14, 28 (ระหว่าง section ในฟอร์ม)
- **Touch target ขั้นต่ำ 44×44px** (ห้ามต่ำกว่านี้ ยกเว้นข้อความลิงก์)
- Radius: ชิป/ปุ่มทั่วไป 12 · การ์ด 14–16 · แถบสรุปลอย 18 · pill 99
- เงา: ใช้แค่แถบสรุปลอย `0 6px 18px rgba(5,76,76,.25)` และ header ที่ย่อตอน scroll `0 4px 12px rgba(5,76,76,.08)`

---

## 2. Components

ตั้งชื่อเป็น function component ใน `lib/saneh_web/components/ui.ex` (ชื่อแนะนำ)

### 2.1 Button — `<.button variant={:primary | :secondary | :dashed | :danger}>`

| variant | style |
|---|---|
| `:primary` | สูง 56 (footer) / 52 / 48, พื้น primary, ตัวขาว 16–17/700, radius 14 |
| `:secondary` | สูง 44–52, พื้น surface, ขอบ 1.5 border, ตัว primary 15–16/600 |
| `:dashed` | สูง 52, พื้นโปร่ง, ขอบ 1.5 dashed `--color-border-dashed`, ตัว 15/600 — ใช้กับ "+ เพิ่มตัวเลือก" |
| `:danger` | ตัวอักษร `--color-danger` บนพื้น surface |

ปุ่ม footer ที่มี 2 ปุ่ม: ยกเลิก (secondary, flex 1) + หลัก (primary, flex 2)
ข้อความปุ่มหลักควรบอกผลลัพธ์+ยอด เช่น `ส่งครัว + คิดเงิน · 220`, `เสร็จ · 60`

### 2.2 Chip (ตัวเลือก) — `<.chip selected={bool}>`

- สูง 44, padding 0 14, radius 12, ขอบ 1.5
- **เลือก:** พื้น primary ขอบ primary ตัวขาว 15/600 `aria-pressed="true"`
- **ไม่เลือก:** พื้น surface ขอบ border ตัว primary 15/400
- เรียงด้วย `flex-wrap gap-2`
- กลุ่มเลือก 1 = radio behavior, กลุ่มหลายอย่าง = toggle

### 2.3 Category tabs — `<.category_tabs active="ก๋วยเตี๋ยว">`

- ลำดับตายตัว 7 แท็บ: **ก๋วยเตี๋ยว · ข้าว · กับข้าว · เพิ่มเติม · เครื่องดื่ม · ไอศกรีม · ขนมถุง**
- แท็บ: สูง 38, padding 0 14, radius 99, 15px; active = พื้น primary ตัวขาว 700; inactive = surface + border, 500
- **ปกติ:** `flex-wrap` (2 แถว) ใต้ช่องค้นหา
- **Scroll ลงเกิน ~40px:** header ย่อเป็น sticky — แถวบน `‹ โต๊ะ 1  [🔍]` + แท็บแถวเดียว `overflow-x: auto` ไม่มี scrollbar, ขอบซ้าย/ขวามี gradient fade, auto-scroll ให้แท็บ active อยู่ในจอ — กลับขึ้นบนสุดค่อยกางเป็น 2 แถว (ดู `TabsScrolled`)
- ใช้ component เดียวทุกหน้าสั่งอาหาร ห้ามทำแยก

### 2.4 Segment — `<.segment options={...} value={...}>`

- Track พื้น sand radius 14 padding 4; ปุ่มสูง 44 radius 10
- เลือก = พื้น primary ตัวขาว 700; ไม่เลือก = โปร่ง ตัว muted
- ใช้กับ ถ้วย/โคน, ตำแหน่ง พนักงาน/ผู้จัดการ

### 2.5 Stepper (ตัวนับ) — `<.stepper value={n} min={0}>`

- กล่อง 124×44 radius 12: `[−] N [+]` ปุ่มละ 40px
- **ค่า 0:** ขอบ 1.5 border พื้น surface, `−` สี disabled-soft `aria-disabled`, ตัวเลข 0 สีจาง, `+` พื้นขาวตัว primary
- **ค่า > 0:** ขอบ 2px primary พื้นขาว, `−` พื้น `--color-minus-bg` ตัว brown, ตัวเลข 700, `+` พื้น primary ตัวขาว
- ลดจนเหลือ 0 = ยกเลิกรายการนั้น
- เวอร์ชันเล็กในหน้าสรุป: ปุ่ม 36×36 ขอบ border

### 2.6 Price button + count badge — `<.price_button price={16} count={2}>`

- 76×48 radius 12 แสดงราคา 17/700 (ข้างบนอาจมี label 12px)
- มีจำนวน > 0: ขอบ 2px primary พื้นขาว + badge วงกลม 22px มุมขวาบน (`top:-7px; right:-6px`) พื้น primary ตัวขาว
- ใช้กับตาราง น้ำอัดลม / น้ำเปล่า / ขนมถุง
- ช่องที่ไม่มีขนาดนั้น แสดง `–` สี disabled-soft (ไม่ใช่ปุ่ม)

### 2.7 Switch — `<.switch checked={bool}>`

- 52×30 (หรือ 52×32) radius 99, knob ขาว 24–26
- on = primary, off = `--color-switch-off`; `role="switch" aria-checked`
- ใช้กับ: ใส่ถุงกลับบ้าน, เปิดขาย/หมดวันนี้, เปิดใช้งานพนักงาน, พิมพ์ลงใบครัว, เลขคิวเริ่มใหม่ทุกวัน

### 2.8 Card / List row

- การ์ด: พื้น surface (หรือขาวถ้าเป็นการ์ดสรุป) ขอบ 1.5 border-soft radius 14–16 padding 12–16
- แถวในการ์ด: min-height 64, เส้นคั่น 1px divider
- แถวกดได้ (เมนู, ตั้งค่า): ชื่อ 16/700 + บรรทัดรอง 13 muted + ลูกศร `>` icon-muted
- การ์ดที่มีของสั่งแล้ว: ขอบ 2px primary พื้นขาว

### 2.9 Option group row (หน้าเพิ่มเมนู) — `<.option_group_row>`

- การ์ด radius 16 padding 14/12/14/16 ชื่อกลุ่ม 16/700 + ป้าย + รายการตัวเลือกคั่นด้วย ` · ` 14 muted + `>`
- ป้าย: `ต้องเลือก 1` / `เลือก 1` (พื้น primary-tint ตัว primary) · `เลือกได้หลายอย่าง` (พื้น multi-tag) — 12/600 pill

### 2.10 Table tile (ผังโต๊ะ) — `<.table_tile>`

- Grid 3 คอลัมน์ gap 10 สูง 88–96 radius 16
- **ว่าง:** พื้น surface ขอบ border เลขโต๊ะ 26/700 + "ว่าง" 12.5 muted
- **มีลูกค้า:** พื้น wait-bg ขอบ wait-border ตัว wait-text + pill คิวมุมซ้ายบน (พื้น wait-text ตัวขาว 11.5/700) แสดง **ทุกรอบ** เช่น `#3 #7`
- ไม่มีสถานะ "กำลังทำ" — โต๊ะกลับเป็นว่างเมื่อคิดเงินแล้วเท่านั้น

### 2.11 Bottom nav — `<.bottom_nav current={...} role={...}>`

- สูง 72, ขอบบน border-soft, grid 5 ช่อง: **รับออเดอร์ · จัดการเมนู · ยอดขาย · บัญชี · ตั้งค่า**
- ไอคอน 24 stroke 1.8 (active 2.0) + label 12.5
- active: สี primary 700; ปกติ: muted
- **ไม่มีสิทธิ์:** สี `--color-disabled` **ไม่มีไอคอนกุญแจ** `aria-disabled="true"`; แตะแล้วขึ้น toast "… เปิดได้เฉพาะเจ้าของร้าน"

### 2.12 Order bar (แถบสรุปลอย) — `<.order_bar count={3} total={170}>`

- absolute ล่าง 16px ซ้าย-ขวา 12px สูง 64 radius 18 พื้น primary + เงา
- ซ้าย: วงกลมขาว 32 จำนวนชิ้น + "ยังไม่ส่งครัว" 13 + ยอด 19/700; ขวา: ปุ่มขาว "สรุปออเดอร์ →"
- เนื้อหาหน้าต้องมี padding-bottom ≥ 110px กันโดนบัง

### 2.13 Footer bar (หน้าตัวเลือก/สรุป)

- sticky ล่าง พื้น bg ขอบบน border-soft padding 12/16/20
- แถว "รวม … บาท" (28/700) + ปุ่มหลัก

### 2.14 Note box / Hint

- พื้น sand radius 12 padding 12/14 ตัว note-text 14 line-height 1.5
- ป้ายหมายเหตุในรายการ: พื้น note-bg ตัว brown 14/600 radius 8 `หมายเหตุ: แยกน้ำ`

### 2.15 Toast — `<.toast action="ยกเลิก">`

- absolute เหนือ order bar (bottom ~92) สูง 48 radius 12 พื้น wait-text ตัวขาว 14.5
- ปุ่ม action พื้น wait-bg ตัว wait-text 700; หายเองใน ~4 วิ
- ใช้: ยืนยันการเพิ่มแบบแตะครั้งเดียว (undo), แจ้งไม่มีสิทธิ์

### 2.16 Top bar

- ซ้าย: ปุ่ม back 44×44 ไอคอน `‹` (chevron 22) · กลาง: ชื่อ 24/700 (+ subtitle 13 muted) · ขวา: action รอง (ย้ายโต๊ะ, + สั่งเพิ่ม, ป้ายตำแหน่ง)
- หน้าแรกพนักงาน: ขวาบนเป็น **ชื่อพนักงาน + ปุ่ม "ออก"** (logout) เท่านั้น

### 2.17 Input / Select

- สูง 48 radius 12 ขอบ 1.5 border พื้น surface padding 0 14 ตัว 16–18
- focus: ขอบ 2px primary พื้นขาว
- label เหนือช่อง 14/600, hint ใต้ช่อง 13 muted

### 2.18 PIN — `<.pin_dots filled={2}>` + `<.keypad>`

- จุด 16–18px: เต็ม = primary, ว่าง = ขอบ 2px border-dashed
- Keypad grid 3×4 ปุ่มสูง 64 radius 16 ตัวเลข 26/600; แถวล่าง: (ปุ่มพิเศษ เช่น "สุ่มให้") · 0 · ⌫
- Name tile (login): 96px สูง radius 16, avatar ตัวอักษรแรก 40px, ชื่อ 15/700, ตำแหน่ง 12/600

### 2.19 Role badge

| ตำแหน่ง | พื้น | ตัว |
|---|---|---|
| พนักงาน | primary-tint | primary |
| ผู้จัดการ | sand `#F1E6C4` | brown `#8A4B12` |
| เจ้าของ | primary | ขาว |

### 2.20 ใบครัว / ใบเสร็จ

แยกไปไว้ที่ `PRINT.md` แล้ว (พิมพ์ผ่าน thermal printer ใช้ระบบคนละแบบกับหน้าจอ)

---

## 3. Interaction rules (ใช้ทั้งแอป)

1. แตะครั้งเดียวต้องได้ผล — ไม่บังคับเลือกโหมด/ขนาดก่อน (ตารางราคา, stepper)
2. ทุกอย่างอยู่หน้าเดียว — ตัวเลือกย่อยใช้ panel กางในหน้า (เหมือน "ทะเลใส่อะไร") ไม่เปิด sheet/หน้าใหม่ซ้อน
3. หน้าคล้ายกันต้องหน้าตาเหมือนกันทุกหน้า (แท็บ, footer, ตำแหน่ง switch ใส่ถุง)
4. ของที่ไม่มีสิทธิ์ = เห็นแต่เป็นสีเทา ไม่ซ่อน ไม่ใส่กุญแจ
5. ยืนยันการกระทำถาวรด้วยข้อความบนปุ่ม (เช่น "ยืนยันรหัสใหม่") ไม่ใช้ `alert()`
6. ราคาแสดงเป็นจำนวนเต็มบาท ไม่มีทศนิยม ไม่มีสัญลักษณ์ ฿ (เขียน "บาท")
