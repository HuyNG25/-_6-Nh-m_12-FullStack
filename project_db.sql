-- =======================================================
-- SQL Server Unified Database Script (Schema + Seed Data)
-- Database Name: ProjectDB
-- Suitable for: NHÓM 12 - Project & Member Service
-- =======================================================

-- -------------------------------------------------------
-- PART 1: DATABASE & TABLES CREATION
-- -------------------------------------------------------

-- 1. Create Database if it does not exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'ProjectDB')
BEGIN
    CREATE DATABASE [ProjectDB];
END
GO

USE [ProjectDB];
GO

-- Disable referential integrity check temporarily to clean up existing tables cleanly if they exist
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_Milestones_Projects_ProjectId')
    ALTER TABLE [dbo].[Milestones] DROP CONSTRAINT [FK_Milestones_Projects_ProjectId];
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_Sprints_Projects_ProjectId')
    ALTER TABLE [dbo].[Sprints] DROP CONSTRAINT [FK_Sprints_Projects_ProjectId];
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_ProjectMembers_Projects_ProjectId')
    ALTER TABLE [dbo].[ProjectMembers] DROP CONSTRAINT [FK_ProjectMembers_Projects_ProjectId];
GO

-- Drop tables if they exist to start fresh
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Milestones]') AND type in (N'U'))
    DROP TABLE [dbo].[Milestones];
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Sprints]') AND type in (N'U'))
    DROP TABLE [dbo].[Sprints];
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProjectMembers]') AND type in (N'U'))
    DROP TABLE [dbo].[ProjectMembers];
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
    DROP TABLE [dbo].[Projects];
GO

-- 2. Create Projects Table
CREATE TABLE [dbo].[Projects] (
    [Id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(2000) NULL,
    [StartDate] DATETIME2 NOT NULL,
    [EndDate] DATETIME2 NULL,
    [Color] NVARCHAR(7) NULL,
    [Status] NVARCHAR(50) NOT NULL, -- Stored as string enum (Active, Completed, Archived)
    [CreatedBy] NVARCHAR(450) NOT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

-- 3. Create ProjectMembers Table
CREATE TABLE [dbo].[ProjectMembers] (
    [Id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ProjectId] UNIQUEIDENTIFIER NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [DisplayName] NVARCHAR(200) NOT NULL,
    [Email] NVARCHAR(300) NULL,
    [Role] NVARCHAR(50) NOT NULL, -- Stored as string enum (Owner, Manager, Member, Viewer)
    [JoinedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_ProjectMembers] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ProjectMembers_Projects_ProjectId] FOREIGN KEY ([ProjectId]) 
        REFERENCES [dbo].[Projects] ([Id]) ON DELETE CASCADE
);
GO

-- Unique Index: A user can only be added to a project once
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProjectMembers_ProjectId_UserId]
    ON [dbo].[ProjectMembers] ([ProjectId] ASC, [UserId] ASC);
GO

-- 4. Create Sprints Table
CREATE TABLE [dbo].[Sprints] (
    [Id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ProjectId] UNIQUEIDENTIFIER NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Goal] NVARCHAR(1000) NULL,
    [StartDate] DATETIME2 NOT NULL,
    [EndDate] DATETIME2 NOT NULL,
    [Status] NVARCHAR(50) NOT NULL, -- Stored as string enum (Planning, Active, Completed)
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Sprints] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Sprints_Projects_ProjectId] FOREIGN KEY ([ProjectId]) 
        REFERENCES [dbo].[Projects] ([Id]) ON DELETE CASCADE
);
GO

-- 5. Create Milestones Table
CREATE TABLE [dbo].[Milestones] (
    [Id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ProjectId] UNIQUEIDENTIFIER NOT NULL,
    [Title] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(1000) NULL,
    [DueDate] DATETIME2 NOT NULL,
    [IsCompleted] BIT NOT NULL DEFAULT 0,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Milestones] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Milestones_Projects_ProjectId] FOREIGN KEY ([ProjectId]) 
        REFERENCES [dbo].[Projects] ([Id]) ON DELETE CASCADE
);
GO

PRINT 'Database structure created successfully.';
GO


-- -------------------------------------------------------
-- PART 2: SEED DATA INSERTION
-- -------------------------------------------------------

-- Declare temporary Project GUID variables
DECLARE @Proj1 UNIQUEIDENTIFIER = 'A0E64669-7A8B-4B2D-8C54-7278EEAD8E1A';
DECLARE @Proj2 UNIQUEIDENTIFIER = 'B7E235C1-2856-4EE6-9310-47F15A36A9D9';
DECLARE @Proj3 UNIQUEIDENTIFIER = 'C5FA8E62-F4A3-4C3D-8822-2616D713E22F';
DECLARE @Proj4 UNIQUEIDENTIFIER = 'D3C4A5E7-6B18-479D-A3D3-524C281F1A7E';
DECLARE @Proj5 UNIQUEIDENTIFIER = 'E9F8E7D6-C5B4-4321-A9D8-654C281F1D4C';

-- Insert 5 Projects
INSERT INTO [dbo].[Projects] ([Id], [Name], [Description], [StartDate], [EndDate], [Color], [Status], [CreatedBy], [CreatedAt], [UpdatedAt])
VALUES
(@Proj1, N'Hệ thống E-Commerce Bán hàng Trực tuyến', N'Dự án phát triển nền tảng mua sắm trực tuyến tích hợp cổng thanh toán vnpay.', '2026-05-01 00:00:00', '2026-12-31 00:00:00', '#FF5733', 'Active', 'owner_user_1', GETUTCDATE(), GETUTCDATE()),
(@Proj2, N'Website Tuyển dụng & Tìm kiếm Việc làm', N'Nền tảng giúp kết nối nhà tuyển dụng công nghệ với các lập trình viên.', '2026-06-01 00:00:00', '2026-10-30 00:00:00', '#33FF57', 'Active', 'owner_user_2', GETUTCDATE(), GETUTCDATE()),
(@Proj3, N'Ứng dụng Di động Theo dõi Sức khỏe', N'App di động đếm bước chân, tính lượng calo và gợi ý chế độ ăn uống lành mạnh.', '2026-05-15 00:00:00', NULL, '#3357FF', 'Active', 'owner_user_3', GETUTCDATE(), GETUTCDATE()),
(@Proj4, N'Hệ thống CRM Quản lý Quan hệ Khách hàng', N'Phần mềm chăm sóc khách hàng và tối ưu quy trình bán hàng doanh nghiệp.', '2026-04-01 00:00:00', '2026-09-01 00:00:00', '#F0B27A', 'Active', 'owner_user_4', GETUTCDATE(), GETUTCDATE()),
(@Proj5, N'Nền tảng Học trực tuyến E-Learning', N'Hệ thống quản lý khóa học video, livestream dạy học trực tuyến và làm bài thi.', '2026-06-10 00:00:00', '2027-03-31 00:00:00', '#8E44AD', 'Active', 'owner_user_5', GETUTCDATE(), GETUTCDATE());

-- Insert Project Members
INSERT INTO [dbo].[ProjectMembers] ([Id], [ProjectId], [UserId], [DisplayName], [Email], [Role], [JoinedAt])
VALUES
-- Project 1 (E-Commerce)
(NEWID(), @Proj1, 'owner_user_1', N'Nguyễn Văn A', 'owner1@example.com', 'Owner', GETUTCDATE()),
(NEWID(), @Proj1, 'manager_user_1', N'Trần Thị B', 'manager1@example.com', 'Manager', GETUTCDATE()),
(NEWID(), @Proj1, 'dev_user_1', N'Lê Văn C', 'dev1@example.com', 'Member', GETUTCDATE()),
(NEWID(), @Proj1, 'dev_user_2', N'Phạm Văn D', 'dev2@example.com', 'Member', GETUTCDATE()),

-- Project 2 (Tuyển dụng)
(NEWID(), @Proj2, 'owner_user_2', N'Đỗ Minh Quân', 'owner2@example.com', 'Owner', GETUTCDATE()),
(NEWID(), @Proj2, 'dev_user_3', N'Nguyễn Hoàng Nam', 'dev3@example.com', 'Member', GETUTCDATE()),

-- Project 3 (Sức khỏe)
(NEWID(), @Proj3, 'owner_user_3', N'Phan Thanh Hằng', 'owner3@example.com', 'Owner', GETUTCDATE()),
(NEWID(), @Proj3, 'manager_user_2', N'Hoàng Gia Bảo', 'manager2@example.com', 'Manager', GETUTCDATE()),
(NEWID(), @Proj3, 'dev_user_4', N'Lê Minh Triết', 'dev4@example.com', 'Member', GETUTCDATE()),
(NEWID(), @Proj3, 'viewer_user_1', N'Trương Mỹ Linh', 'viewer1@example.com', 'Viewer', GETUTCDATE()),

-- Project 4 (CRM)
(NEWID(), @Proj4, 'owner_user_4', N'Vũ Hoàng Nam', 'owner4@example.com', 'Owner', GETUTCDATE()),

-- Project 5 (E-Learning)
(NEWID(), @Proj5, 'owner_user_5', N'Lý Khánh Hòa', 'owner5@example.com', 'Owner', GETUTCDATE()),
(NEWID(), @Proj5, 'dev_user_5', N'Ngô Gia Huy', 'dev5@example.com', 'Member', GETUTCDATE());

-- Insert Sprints
INSERT INTO [dbo].[Sprints] ([Id], [ProjectId], [Name], [Goal], [StartDate], [EndDate], [Status], [CreatedAt])
VALUES
-- Project 1 Sprints
(NEWID(), @Proj1, N'Sprint 1: Thiết kế cơ sở dữ liệu & API Đăng ký/Đăng nhập', N'Hoàn thành thiết kế thực thể DB và các API Auth cơ bản.', '2026-05-01 00:00:00', '2026-05-15 00:00:00', 'Completed', GETUTCDATE()),
(NEWID(), @Proj1, N'Sprint 2: Phát triển giỏ hàng & Cổng thanh toán', N'Hoàn thiện luồng checkout và tích hợp API VnPay.', '2026-06-10 00:00:00', '2026-06-24 00:00:00', 'Active', GETUTCDATE()),

-- Project 2 Sprints
(NEWID(), @Proj2, N'Sprint 1: Phát triển bộ tìm kiếm và bộ lọc việc làm', N'Hoàn thành API ElasticSearch và UI tìm kiếm nâng cao.', '2026-06-12 00:00:00', '2026-06-26 00:00:00', 'Active', GETUTCDATE()),

-- Project 3 Sprints
(NEWID(), @Proj3, N'Sprint 1: Kết nối thiết bị qua Bluetooth', N'Tích hợp SDK đọc dữ liệu nhịp tim và bước chân.', '2026-06-20 00:00:00', '2026-07-04 00:00:00', 'Planning', GETUTCDATE()),

-- Project 4 Sprints
(NEWID(), @Proj4, N'Sprint 1: Quản lý khách hàng tiềm năng (Leads)', N'Cho phép tạo, cập nhật trạng thái và gán lead cho nhân viên sales.', '2026-06-05 00:00:00', '2026-06-19 00:00:00', 'Active', GETUTCDATE()),

-- Project 5 Sprints
(NEWID(), @Proj5, N'Sprint 1: Tải lên và Stream video bài giảng', N'Xây dựng luồng tải lên video lên cloud và xem video với chất lượng HD.', '2026-06-15 00:00:00', '2026-06-29 00:00:00', 'Planning', GETUTCDATE());

-- Insert Milestones
INSERT INTO [dbo].[Milestones] ([Id], [ProjectId], [Title], [Description], [DueDate], [IsCompleted], [CreatedAt])
VALUES
-- Project 1 Milestones
(NEWID(), @Proj1, N'Hoàn thành MVP v1.0', N'Bàn giao phiên bản thử nghiệm có thể mua hàng cơ bản cho khách hàng.', '2026-07-15 00:00:00', 0, GETUTCDATE()),

-- Project 2 Milestones
(NEWID(), @Proj2, N'Bàn giao UI/UX Prototype', N'Khách hàng phê duyệt bản thiết kế UI/UX trên Figma trước khi bắt đầu lập trình giao diện.', '2026-06-05 00:00:00', 1, GETUTCDATE()),

-- Project 3 Milestones
(NEWID(), @Proj3, N'Kiểm thử Beta nội bộ', N'Phát hành bản beta thử nghiệm nội bộ cho nhóm 50 nhân viên công ty.', '2026-08-01 00:00:00', 0, GETUTCDATE()),

-- Project 4 Milestones
(NEWID(), @Proj4, N'Tích hợp tổng đài ảo IP', N'Cho phép nhân viên gọi điện trực tiếp cho khách hàng từ giao diện CRM.', '2026-07-30 00:00:00', 0, GETUTCDATE()),

-- Project 5 Milestones
(NEWID(), @Proj5, N'Ra mắt chương trình học đầu tiên', N'Chuẩn bị đủ 10 khóa học chất lượng cao để chính thức mở cổng đăng ký học viên.', '2026-09-15 00:00:00', 0, GETUTCDATE());

PRINT 'Seed data inserted successfully.';
GO
