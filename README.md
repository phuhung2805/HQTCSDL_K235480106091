HQTCSDL_K235480106091

Phần 1: Thiết kế và Khởi tạo Cấu trúc Dữ liệu (Kiến thức 6, 7)

1. Thông tin chung
Chủ đề: Quản lý siêu thị mini  
Tên Database: [QuanLySieuThi_K235480106091] (Đã bao gồm Mã SV theo yêu cầu)  

2. Thiết kế bảng và Ràng buộc
Hệ thống sử dụng quy tắc đặt tên BướuLạcĐà (PascalCase) và bọc tên bằng cặp ngoặc [ ]:  
 Bảng [NhomHang]: Phân loại các nhóm sản phẩm (Ví dụ: Thực phẩm, Đồ gia dụng).    
  PK: [MaNhom] (Số nguyên tự tăng).  
 Bảng [SanPham]: Lưu trữ thông tin chi tiết các mặt hàng.    
  PK: [MaSanPham].    
  FK: [MaNhom] liên kết đến bảng [NhomHang].    
  CK: [GiaBan] >= 0 và [SoLuongTon] >= 0 để đảm bảo dữ liệu không bị âm.  
 Bảng [KhachHang]: Quản lý thông tin và điểm tích lũy của khách.    
  CK: [DiemTichLuy] >= 0.  

3. Mã SQL Khởi tạo

-- Tạo Database
CREATE DATABASE [QuanLySieuThi_K235480106091];
GO
USE [QuanLySieuThi_K235480106091];
GO

-- Tạo bảng Nhóm Hàng
CREATE TABLE [NhomHang] (
    [MaNhom] INT IDENTITY(1,1) PRIMARY KEY, -- Khóa chính PK
    [TenNhom] NVARCHAR(100) NOT NULL -- Chuỗi Unicode
);

-- Tạo bảng Sản Phẩm
CREATE TABLE [SanPham] (
    [MaSanPham] CHAR(10) PRIMARY KEY, -- Khóa chính PK
    [TenSanPham] NVARCHAR(200) NOT NULL, -- Chuỗi Unicode
    [GiaBan] DECIMAL(18, 2) NOT NULL CHECK ([GiaBan] >= 0), -- Tiền tệ & Ràng buộc CK
    [SoLuongTon] INT DEFAULT 0 CHECK ([SoLuongTon] >= 0), -- Số nguyên & Ràng buộc CK
    [MaNhom] INT,
    [NgayNhap] DATE DEFAULT GETDATE(), -- Ngày tháng
    CONSTRAINT [FK_SanPham_NhomHang] FOREIGN KEY ([MaNhom]) REFERENCES [NhomHang]([MaNhom]) -- Khóa ngoại FK
);

-- Tạo bảng Khách Hàng
CREATE TABLE [KhachHang] (
    [MaKH] INT IDENTITY(1,1) PRIMARY KEY,
    [HoTen] NVARCHAR(100),
    [DiemTichLuy] INT DEFAULT 0 CHECK ([DiemTichLuy] >= 0)
);
GO

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9ecb1dce-a131-4a52-8e7d-fe77736e7131" />
