# NHÓM 1 - Project & Member Service API (Đề tài 06)

Hệ thống quản lý dự án & phân công công việc theo mô hình Kanban/Scrum sử dụng kiến trúc Microservices. Đây là dịch vụ **Project & Member Service** đảm nhận quản lý dự án, phân quyền thành viên, quản lý sprint và các mốc thời gian quan trọng (milestones).

Dự án sử dụng cơ sở dữ liệu **ProjectDB** (lưu trữ trong bộ nhớ - InMemory Database cho môi trường phát triển) và tích hợp sẵn Swagger UI cùng cơ chế mô phỏng phát sự kiện (Event Publishing) phục vụ trao đổi thông điệp giữa các microservices.

---

## 1. Công nghệ sử dụng
- **Framework**: ASP.NET Core 10.0 Web API
- **ORM**: Entity Framework Core với InMemory Database
- **Tài liệu hóa API**: OpenAPI / Swagger UI
- **Hạ tầng**: Dockerfile & docker-compose.yml

---

## 2. Các chức năng và Quy tắc nghiệp vụ chính

### Quản lý Dự án (Projects)
- Hỗ trợ đầy đủ các thao tác CRUD (Thêm, Đọc danh sách/Chi tiết, Sửa, Xóa).
- Khi tạo dự án mới, tài khoản tạo (`X-User-Id`) sẽ tự động được gán vai trò **Owner** của dự án đó.
- Mã màu nhận diện phải tuân thủ định dạng Hex (`#RRGGBB`).
- Ngày kết thúc của dự án (nếu có) phải lớn hơn hoặc bằng ngày bắt đầu.

### Phân quyền thành viên (Project Members)
- Các vai trò (Roles) trong dự án gồm: `Owner`, `Manager`, `Member`, `Viewer`.
- **Owner**: Có toàn quyền đối với dự án (bao gồm cả việc xóa dự án).
- **Manager**: Có quyền thêm/xóa thành viên, đổi vai trò thành viên, tạo sprint, tạo milestone. 
  - *Giới hạn*: Manager không được tác động đến vai trò của Manager khác hoặc Owner; không được phong chức Manager/Owner cho người khác; không được xóa Manager/Owner khỏi dự án.
- **Member/Developer** & **Viewer**: Không có quyền thay đổi thành viên hoặc cấu trúc dự án.

### Quản lý Sprint
- Thời gian chạy mặc định của một sprint là **14 ngày (2 tuần)**.
- Ngày bắt đầu và ngày kết thúc của Sprint phải nằm trong phạm vi hiệu lực của dự án.
- Mỗi dự án tại một thời điểm chỉ cho phép tối đa **1 Sprint hoạt động (Active)**.

### Quản lý Mốc quan trọng (Milestones)
- Lưu trữ các mốc thời gian quan trọng phục vụ theo dõi tiến độ.
- Ngày đến hạn (`DueDate`) của Milestone phải nằm trong khoảng từ `StartDate` đến `EndDate` (nếu có) của dự án.

### Cơ chế Publish Event (Mô phỏng)
- Chuẩn hóa việc gửi các thông điệp JSON khi có hành động xảy ra trong hệ thống thông qua `IEventPublisher`:
  - Sự kiện `project.member.added`: Phát ra khi thêm thành viên mới.
  - Sự kiện `sprint.started`: Phát ra khi bắt đầu một Sprint mới.
- Event payload được in trực quan dưới dạng JSON đẹp trên Console log của ứng dụng.

---

## 3. Hướng dẫn chạy và truy cập Swagger API

### Cách 1: Chạy trực tiếp từ mã nguồn (.NET 10 SDK)

**Yêu cầu**: Cài đặt .NET 10 SDK trên máy.

1. Mở terminal tại thư mục chứa mã nguồn:
   ```bash
   cd ProjectMemberService
   ```
2. Restore và build dự án:
   ```bash
   dotnet build
   ```
3. Khởi chạy API Server:
   ```bash
   dotnet run --urls "http://localhost:5100"
   ```
4. Truy cập giao diện **Swagger UI** tại trình duyệt:
   [http://localhost:5100/swagger](http://localhost:5100/swagger) (Hệ thống sẽ tự động chuyển hướng từ trang chủ `http://localhost:5100` sang giao diện Swagger UI).

---

### Cách 2: Khởi chạy bằng Docker Compose

**Yêu cầu**: Cài đặt Docker và Docker Compose trên máy.

1. Đứng tại thư mục gốc của dự án (nơi chứa file `docker-compose.yml`):
   ```bash
   docker-compose up -d --build
   ```
2. Container sẽ tự động build mã nguồn và khởi chạy Web API trên cổng `5100`.
3. Truy cập Swagger UI tại: [http://localhost:5100/swagger](http://localhost:5100/swagger).

---

## 4. Hướng dẫn thử nghiệm các API trên Swagger UI

Do hệ thống sử dụng cơ chế đọc thông tin định danh người dùng từ JWT Token hoặc tiêu đề HTTP custom phục vụ mục đích kiểm thử nhanh (không cần qua cổng API Gateway), bạn có thể dễ dàng kiểm tra phân quyền bằng cách sau:

1. **Tạo dự án mới**:
   - Sử dụng endpoint `POST /api/Projects`.
   - Trong Swagger UI, nhấn **Try it out**, nhập request body.
   - Tại mục Headers, bạn có thể truyền tiêu đề `X-User-Id` là một chuỗi tùy ý (ví dụ: `owner_user_1`). Người dùng này sẽ tự động trở thành **Owner** của dự án mới tạo.
   - Sao chép trường `id` (GUID) từ dữ liệu trả về để làm `projectId` cho các bước tiếp theo.

2. **Thêm thành viên**:
   - Sử dụng endpoint `POST /api/projects/{projectId}/Members`.
   - Nhập `projectId` đã copy ở bước trước.
   - Nhập thông tin thành viên mới vào request body.
   - Để kiểm thử phân quyền thành công, hãy đặt header `X-User-Id` khớp với người tạo dự án ban đầu (ví dụ: `owner_user_1`). Nếu bạn đổi sang một user lạ khác, API sẽ báo lỗi `400 Bad Request` do không có quyền quản lý thành viên.

3. **Tạo và bắt đầu Sprint / Milestone**:
   - Thực hiện tương tự tại các endpoint thuộc nhóm Sprints và Milestones.
   - Kiểm tra log console của ứng dụng (hoặc logs của docker container) để xem các JSON payload được gửi đi tự động khi phát sự kiện thành viên mới (`project.member.added`) hoặc bắt đầu sprint (`sprint.started`).
