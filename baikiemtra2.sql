-- ==========================================
-- PHẦN 1: THIẾT KẾ VÀ KHỞI TẠO CẤU TRÚC DỮ LIỆU
-- ==========================================

CREATE DATABASE [QuanLySieuThi_K235480106091];
GO
USE [QuanLySieuThi_K235480106091];
GO

CREATE TABLE [NhomHang] (
    [MaNhom] INT IDENTITY(1,1) PRIMARY KEY,
    [TenNhom] NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE [SanPham] (
    [MaSanPham] CHAR(10) PRIMARY KEY,
    [TenSanPham] NVARCHAR(200) NOT NULL,
    [GiaBan] DECIMAL(18, 2) NOT NULL CHECK ([GiaBan] >= 0),
    [SoLuongTon] INT DEFAULT 0 CHECK ([SoLuongTon] >= 0),
    [MaNhom] INT,
    [NgayNhap] DATE DEFAULT GETDATE(),
    CONSTRAINT [FK_SanPham_NhomHang] FOREIGN KEY ([MaNhom]) REFERENCES [NhomHang]([MaNhom])
);
GO

CREATE TABLE [HoaDon] (
    [MaHoaDon] INT IDENTITY(1,1) PRIMARY KEY,
    [NgayLap] DATETIME DEFAULT GETDATE(),
    [TongTien] DECIMAL(18, 2) DEFAULT 0
);
GO

CREATE TABLE [ChiTietHoaDon] (
    [MaHoaDon] INT,
    [MaSanPham] CHAR(10),
    [SoLuong] INT NOT NULL CHECK ([SoLuong] > 0),
    [DonGia] DECIMAL(18, 2) NOT NULL,
    PRIMARY KEY ([MaHoaDon], [MaSanPham]),
    CONSTRAINT [FK_CTHD_HoaDon] FOREIGN KEY ([MaHoaDon]) REFERENCES [HoaDon]([MaHoaDon]),
    CONSTRAINT [FK_CTHD_SanPham] FOREIGN KEY ([MaSanPham]) REFERENCES [SanPham]([MaSanPham])
);
GO

INSERT INTO [NhomHang] ([TenNhom]) VALUES (N'Đồ gia dụng'), (N'Thực phẩm');
INSERT INTO [SanPham] ([MaSanPham], [TenSanPham], [GiaBan], [SoLuongTon], [MaNhom]) 
VALUES ('SP01', N'Nước mắm', 50000, 100, 2), ('SP02', N'Chảo chống dính', 150000, 50, 1);
GO

-- ==========================================
-- PHẦN 2: XÂY DỰNG FUNCTION
-- ==========================================

CREATE FUNCTION [dbo].[fn_TinhDoanhThuNgay] (@Ngay DATETIME)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Tong DECIMAL(18, 2);
    SELECT @Tong = SUM([TongTien]) FROM [HoaDon] WHERE CAST([NgayLap] AS DATE) = CAST(@Ngay AS DATE);
    RETURN ISNULL(@Tong, 0);
END;
GO

CREATE FUNCTION [dbo].[fn_LaySanPhamTheoNhom] (@MaNhom INT)
RETURNS TABLE
AS
RETURN (
    SELECT [MaSanPham], [TenSanPham], [GiaBan], [SoLuongTon]
    FROM [SanPham]
    WHERE [MaNhom] = @MaNhom
);
GO

CREATE FUNCTION [dbo].[fn_CanhBaoTonKho] (@MucTonKho INT)
RETURNS @BangCanhBao TABLE (
    [MaSanPham] CHAR(10),
    [TenSanPham] NVARCHAR(200),
    [TrangThai] NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @BangCanhBao
    SELECT [MaSanPham], [TenSanPham], N'Sắp hết hàng, cần nhập!'
    FROM [SanPham]
    WHERE [SoLuongTon] <= @MucTonKho;
    RETURN;
END;
GO

-- ==========================================
-- PHẦN 3: XÂY DỰNG STORE PROCEDURE
-- ==========================================

CREATE PROCEDURE [sp_ThemHoaDon]
    @MaHoaDonMoi INT OUTPUT
AS
BEGIN
    INSERT INTO [HoaDon] ([NgayLap], [TongTien]) VALUES (GETDATE(), 0);
    SET @MaHoaDonMoi = SCOPE_IDENTITY();
END;
GO

CREATE PROCEDURE [sp_BaoCaoHoaDon]
    @MaHoaDon INT
AS
BEGIN
    SELECT h.[MaHoaDon], h.[NgayLap], c.[MaSanPham], s.[TenSanPham], c.[SoLuong], c.[DonGia], (c.[SoLuong] * c.[DonGia]) AS [ThanhTien]
    FROM [HoaDon] h
    JOIN [ChiTietHoaDon] c ON h.[MaHoaDon] = c.[MaHoaDon]
    JOIN [SanPham] s ON c.[MaSanPham] = s.[MaSanPham]
    WHERE h.[MaHoaDon] = @MaHoaDon;
END;
GO

-- ==========================================
-- PHẦN 4: TRIGGER VÀ XỬ LÝ LOGIC NGHIỆP VỤ
-- ==========================================

CREATE TRIGGER [trg_BanHang_TruTonKho]
ON [ChiTietHoaDon]
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET s.[SoLuongTon] = s.[SoLuongTon] - i.[SoLuong]
    FROM [SanPham] s
    JOIN inserted i ON s.[MaSanPham] = i.[MaSanPham];

    UPDATE h
    SET h.[TongTien] = h.[TongTien] + (i.[SoLuong] * i.[DonGia])
    FROM [HoaDon] h
    JOIN inserted i ON h.[MaHoaDon] = i.[MaHoaDon];
END;
GO

-- ==========================================
-- PHẦN 5: CURSOR VÀ DUYỆT DỮ LIỆU
-- ==========================================

DECLARE @MaSP CHAR(10), @Gia DECIMAL(18,2);
DECLARE cur_GiamGia CURSOR FOR SELECT [MaSanPham], [GiaBan] FROM [SanPham] WHERE [MaNhom] = 1;

OPEN cur_GiamGia;
FETCH NEXT FROM cur_GiamGia INTO @MaSP, @Gia;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE [SanPham] SET [GiaBan] = @Gia * 0.9 WHERE CURRENT OF cur_GiamGia;
    FETCH NEXT FROM cur_GiamGia INTO @MaSP, @Gia;
END;

CLOSE cur_GiamGia;
DEALLOCATE cur_GiamGia;
GO