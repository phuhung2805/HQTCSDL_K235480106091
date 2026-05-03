# HQTCSDL_K235480106091

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
![alt text](https://github.com/user-attachments/assets/9ecb1dce-a131-4a52-8e7d-fe77736e7131)

