# HQTCSDL_K235480106091

- **Họ và tên:** Nguyễn Phú Hưng
- **Mã sinh viên:** K235480106091
- **Lớp:** K59
- **Chuyên ngành:** Kỹ thuật Máy tính
- **Trường:** Đại học Kỹ thuật Công nghiệp Thái Nguyên (TNUT)
- **Môn học:** Hệ quản trị cơ sở dữ liệu - TEE560
- 
## Phần 1: Thiết kế và Khởi tạo Cấu trúc Dữ liệu (Kiến thức 6, 7)

### 1. Thông tin chung
Chủ đề: Quản lý siêu thị mini  
Tên Database: [QuanLySieuThi_K235480106091]

### 2. Thiết kế bảng và Ràng buộc
Hệ thống sử dụng quy tắc đặt tên BướuLạcĐà (PascalCase) và bọc tên bằng cặp ngoặc [ ]:  

- Bảng [NhomHang]: Phân loại các nhóm sản phẩm. PK: [MaNhom].  
- Bảng [SanPham]: Lưu trữ thông tin chi tiết các mặt hàng. PK: [MaSanPham], FK: [MaNhom].  
- Bảng [KhachHang]: Quản lý thông tin và điểm tích lũy của khách.

### 3. Mã SQL Khởi tạo
```sql
CREATE DATABASE [QuanLySieuThi_K235480106091];
GO
USE [QuanLySieuThi_K235480106091];
GO

CREATE TABLE [NhomHang] (
    [MaNhom] INT IDENTITY(1,1) PRIMARY KEY,
    [TenNhom] NVARCHAR(100) NOT NULL
);

CREATE TABLE [SanPham] (
    [MaSanPham] CHAR(10) PRIMARY KEY,
    [TenSanPham] NVARCHAR(200) NOT NULL,
    [GiaBan] DECIMAL(18, 2) NOT NULL CHECK ([GiaBan] >= 0),
    [SoLuongTon] INT DEFAULT 0 CHECK ([SoLuongTon] >= 0),
    [MaNhom] INT,
    [NgayNhap] DATE DEFAULT GETDATE(),
    CONSTRAINT [FK_SanPham_NhomHang] FOREIGN KEY ([MaNhom]) REFERENCES [NhomHang]([MaNhom])
);

CREATE TABLE [KhachHang] (
    [MaKH] INT IDENTITY(1,1) PRIMARY KEY,
    [HoTen] NVARCHAR(100),
    [DiemTichLuy] INT DEFAULT 0 CHECK ([DiemTichLuy] >= 0)
);
GO
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9ecb1dce-a131-4a52-8e7d-fe77736e7131" />

## Phần 2: Xây dựng Function (Kiến thức 8, 9)
### 2.1. Scalar Function: Phân loại khách hàng
Hàm này nhận vào mã khách hàng và trả về hạng khách hàng dựa trên điểm tích lũy.

```sql
CREATE FUNCTION [dbo].[fn_PhanLoaiKhachHang] (@MaKH INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Diem INT, @Loai NVARCHAR(50);
    SELECT @Diem = [DiemTichLuy] FROM [KhachHang] WHERE [MaKH] = @MaKH;
    
    IF @Diem >= 1000 SET @Loai = N'Khách hàng VIP';
    ELSE IF @Diem >= 500 SET @Loai = N'Khách hàng Thân thiết';
    ELSE SET @Loai = N'Khách hàng Mới';
    
    RETURN @Loai;
END;
GO

-- Khai thác:
SELECT [HoTen], [DiemTichLuy], [dbo].[fn_PhanLoaiKhachHang]([MaKH]) AS [Hang] FROM [KhachHang];
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/1a9d0073-fd18-4828-84cc-0544c77052f0" />

### 2.2. Inline Table-Valued Function: Danh sách sản phẩm theo nhóm
Hàm này trả về một bảng chứa danh sách các sản phẩm thuộc một nhóm cụ thể.

```sql
CREATE FUNCTION [dbo].[fn_DanhSachSanPhamTheoNhom] (@MaNhom INT)
RETURNS TABLE
AS
RETURN (
    SELECT [MaSanPham], [TenSanPham], [GiaBan], [SoLuongTon]
    FROM [SanPham]
    WHERE [MaNhom] = @MaNhom
);
GO

-- Khai thác:
SELECT * FROM [dbo].[fn_DanhSachSanPhamTheoNhom](2);
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/97abe6be-d206-437c-bcb4-de3c330e44f4" />

### 2.3. Multi-statement Table-Valued Function: Thống kê giá trị theo nhóm hàng
Mục đích: Sử dụng kỹ thuật xử lý đa câu lệnh (BEGIN...END) và biến bảng để thực hiện các tính toán phức tạp hơn so với hàm Inline thông thường.
Logic nghiệp vụ: Hàm tính toán tổng số lượng tồn và tổng giá trị vốn của từng nhóm hàng. Đồng thời sử dụng CASE WHEN để tự động phân loại mức độ ưu tiên nhập hàng dựa trên tổng vốn tồn kho.

```sql
-- Tạo hàm thống kê giá trị nhóm hàng
CREATE FUNCTION [dbo].[fn_ThongKeGiaTriNhomHang]()
RETURNS @BaoCao TABLE (
    [TenNhom] NVARCHAR(100),
    [TongSoLuong] INT,
    [TongVon] DECIMAL(18, 2),
    [MucDoUuTien] NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @BaoCao
    SELECT 
        n.[TenNhom], 
        SUM(s.[SoLuongTon]), 
        SUM(s.[SoLuongTon] * s.[GiaBan]),
        CASE 
            WHEN SUM(s.[SoLuongTon] * s.[GiaBan]) > 10000000 THEN N'Ưu tiên cao'
            ELSE N'Ưu tiên trung bình'
        END
    FROM [NhomHang] n
    JOIN [SanPham] s ON n.[MaNhom] = s.[MaNhom]
    GROUP BY n.[TenNhom];

    RETURN;
END;
GO

-- KHAI THÁC HÀM:
SELECT * FROM [dbo].[fn_ThongKeGiaTriNhomHang]();
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/26282481-1e10-44c9-99f8-4c40fd53165d" />

## Phần 3: Store Procedure - Thủ tục lưu trữ (Kiến thức 10, 11)

### 1. Lý thuyết về Store Procedure (SP)
Khái niệm: Là một tập hợp các câu lệnh T-SQL được biên dịch sẵn và lưu trữ trong hệ quản trị CSDL.

Ưu điểm: Tối ưu hóa hiệu năng thực thi, giảm lưu lượng đường truyền mạng và tăng tính bảo mật cho dữ liệu.

So sánh: Khác với Function, Store Procedure không bắt buộc trả về giá trị, có thể chứa các lệnh thay đổi dữ liệu như INSERT, UPDATE, DELETE và hỗ trợ tham số đầu ra (OUTPUT).


### 2. Triển khai Store Procedure thực tế

### 3.1. Store Procedure sử dụng tham số OUTPUT
Yêu cầu: Tính tổng doanh thu dựa trên tất cả các hóa đơn hiện có và trả kết quả về cho ứng dụng quản lý thông qua tham số đầu ra.

```sql
CREATE PROCEDURE [dbo].[sp_TongDoanhThuSieuThi]
    @TongTien DECIMAL(18, 2) OUTPUT
AS
BEGIN
    SELECT @TongTien = SUM([TongTien]) FROM [HoaDon];
END;
GO

-- KHAI THÁC SP:
DECLARE @Result DECIMAL(18, 2);
EXEC [dbo].[sp_TongDoanhThuSieuThi] @TongTien = @Result OUTPUT;
SELECT @Result AS [TongDoanhThuHienTai];
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/571f4ccb-ec8b-423c-86f6-ad50e608261c" />

### 3.2. Store Procedure sử dụng kỹ thuật Join nhiều bảng
Yêu cầu: Xuất báo cáo chi tiết cho một khách hàng bất kỳ, bao gồm thông tin cá nhân và lịch sử mua hàng (Tên sản phẩm, số lượng, ngày mua).

```sql
CREATE PROCEDURE [dbo].[sp_LichSuMuaHangKhachHang]
    @MaKH INT
AS
BEGIN
    SELECT 
        k.[HoTen], 
        s.[TenSanPham], 
        c.[SoLuong], 
        h.[NgayLapHD],
        (c.[SoLuong] * c.[DonGia]) AS [ThanhTien]
    FROM [KhachHang] k
    JOIN [HoaDon] h ON k.[MaKH] = h.[MaKH]
    JOIN [ChiTietHoaDon] c ON h.[MaHoaDon] = c.[MaHoaDon]
    JOIN [SanPham] s ON c.[MaSanPham] = s.[MaSanPham]
    WHERE k.[MaKH] = @MaKH;
END;
GO
```
-- KHAI THÁC SP:
EXEC [dbo].[sp_LichSuMuaHangKhachHang] 1;
Chú thích: Các Store Procedure đã được thực thi thành công, xử lý tốt logic tham số OUTPUT và kết nối dữ liệu từ 4 bảng khác nhau để xuất báo cáo chi tiết.

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/6efebc2a-9f3b-453a-b306-8e347e90d5c6" />

## Phần 4: Trigger và Xử lý logic nghiệp vụ

### 1. Lý thuyết về Trigger
Khái niệm: Trigger là một loại thủ tục đặc biệt tự động thực thi khi có các sự kiện thay đổi dữ liệu (INSERT, UPDATE, DELETE) trên bảng.

Mục đích: Đảm bảo tính toàn vẹn dữ liệu và tự động hóa các nghiệp vụ phức tạp (ví dụ: tự động trừ tồn kho khi bán hàng).

### 2. Triển khai Trigger
Yêu cầu: Tự động giảm số lượng hàng trong bảng [SanPham] khi có giao dịch mới được thêm vào bảng [ChiTietHoaDon].

```sql
CREATE TRIGGER [trg_BanHang_TruTonKho]
ON [ChiTietHoaDon]
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET s.[SoLuongTon] = s.[SoLuongTon] - i.[SoLuong]
    FROM [SanPham] s
    JOIN inserted i ON s.[MaSanPham] = i.[MaSanPham];
END;
GO
```
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/4938ebaf-6620-4fdc-8467-81fc09d469ec" />

### 3. Kiểm tra và Minh chứng
Thực hiện lệnh INSERT để kiểm tra sự thay đổi của tồn kho:

sql
-- Kiểm tra tồn kho trước khi bán
SELECT [TenSanPham], [SoLuongTon] FROM [SanPham] WHERE [MaSanPham] = 'SP01';

-- Thực hiện bán 5 sản phẩm
INSERT INTO [ChiTietHoaDon] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGia])
VALUES (1, 'SP01', 5, 50000);

-- Kiểm tra tồn kho sau khi bán
SELECT [TenSanPham], [SoLuongTon] FROM [SanPham] WHERE [MaSanPham] = 'SP01';
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/35ddf031-2bcb-4926-bb2e-6518cfde9b58" />
Chú thích: Ảnh minh chứng số lượng tồn kho đã tự động giảm xuống tương ứng sau khi thực hiện lệnh Insert.


## Phần 5: Cursor và Duyệt dữ liệu

### 1. Lý thuyết về Cursor
Khái niệm: Cursor (Con trỏ) cho phép duyệt và xử lý dữ liệu theo từng dòng (Row-by-row) thay vì xử lý theo tập hợp (Set-based) như các lệnh SQL thông thường.

Mục đích: Sử dụng khi cần thực hiện các logic phức tạp, rẽ nhánh hoặc gọi các thủ tục khác trên từng bản ghi riêng biệt.


### 2. Triển khai Cursor thực tế
Yêu cầu: Duyệt qua bảng [SanPham], kiểm tra tồn kho và in thông báo cảnh báo ra tab Messages.

```sql
DECLARE @MaSP CHAR(10), @TenSP NVARCHAR(200), @TonKho INT;

DECLARE Cursor_KiemTraTonKho CURSOR FOR
SELECT [MaSanPham], [TenSanPham], [SoLuongTon] FROM [SanPham];

OPEN Cursor_KiemTraTonKho;
FETCH NEXT FROM Cursor_KiemTraTonKho INTO @MaSP, @TenSP, @TonKho;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @TonKho < 10
        PRINT N'⚠️ CẢNH BÁO: Sản phẩm [' + @TenSP + N'] sắp hết hàng. Tồn: ' + CAST(@TonKho AS NVARCHAR(10));
    ELSE
        PRINT N'✅ Sản phẩm [' + @TenSP + N'] tồn kho ổn định: ' + CAST(@TonKho AS NVARCHAR(10));

    FETCH NEXT FROM Cursor_KiemTraTonKho INTO @MaSP, @TenSP, @TonKho;
END;

CLOSE Cursor_KiemTraTonKho;
DEALLOCATE Cursor_KiemTraTonKho;
GO
```

### 3. Kết quả thực thi
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/4de7b974-eeb8-4303-ab5b-66cde4a2aeb7" />
Chú thích: Ảnh chụp tab Messages cho thấy Con trỏ đã chạy vòng lặp thành công, duyệt qua từng mặt hàng và in ra cảnh báo mức tồn kho tương ứng với logic rẽ nhánh IF...ELSE.
