using Microsoft.EntityFrameworkCore;
using ProjectMemberService.Data;
using ProjectMemberService.DTOs;
using ProjectMemberService.Models;

namespace ProjectMemberService.Services
{
    public class MemberService : IMemberService
    {
        private readonly ProjectDbContext _context;
        private readonly ILogger<MemberService> _logger;
        private readonly IEventPublisher _eventPublisher;

        public MemberService(ProjectDbContext context, ILogger<MemberService> logger, IEventPublisher eventPublisher)
        {
            _context = context;
            _logger = logger;
            _eventPublisher = eventPublisher;
        }

        public async Task<ApiResponse<MemberResponseDto>> AddMemberAsync(Guid projectId, AddMemberDto dto, string operatorUserId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null)
            {
                return ApiResponse<MemberResponseDto>.Fail("Không tìm thấy dự án");
            }

            // Kiểm tra quyền của người thực hiện
            var operatorMember = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == operatorUserId);

            if (operatorMember == null || (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Manager))
            {
                return ApiResponse<MemberResponseDto>.Fail("Bạn không có quyền quản lý thành viên trong dự án này");
            }

            // Nếu người thực hiện là Manager, họ không thể thêm Owner hoặc Manager khác
            if (operatorMember.Role == MemberRole.Manager && (dto.Role == MemberRole.Owner || dto.Role == MemberRole.Manager))
            {
                return ApiResponse<MemberResponseDto>.Fail("Manager không có quyền thêm Manager hoặc Owner mới");
            }

            // Kiểm tra user đã là thành viên chưa
            var existingMember = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == dto.UserId);

            if (existingMember != null)
            {
                return ApiResponse<MemberResponseDto>.Fail("Người dùng đã là thành viên của dự án");
            }

            var member = new ProjectMember
            {
                ProjectId = projectId,
                UserId = dto.UserId,
                DisplayName = dto.DisplayName,
                Email = dto.Email,
                Role = dto.Role
            };

            _context.ProjectMembers.Add(member);
            await _context.SaveChangesAsync();

            var eventData = new
            {
                ProjectId = member.ProjectId,
                UserId = member.UserId,
                DisplayName = member.DisplayName,
                Email = member.Email,
                Role = member.Role.ToString(),
                JoinedAt = member.JoinedAt
            };
            await _eventPublisher.PublishAsync("project.member.added", eventData);

            return ApiResponse<MemberResponseDto>.Ok(MapToResponse(member), "Thêm thành viên thành công");
        }

        public async Task<ApiResponse<List<MemberResponseDto>>> GetMembersAsync(Guid projectId)
        {
            var projectExists = await _context.Projects.AnyAsync(p => p.Id == projectId);
            if (!projectExists)
            {
                return ApiResponse<List<MemberResponseDto>>.Fail("Không tìm thấy dự án");
            }

            var members = await _context.ProjectMembers
                .Where(m => m.ProjectId == projectId)
                .OrderBy(m => m.JoinedAt)
                .ToListAsync();

            var result = members.Select(MapToResponse).ToList();
            return ApiResponse<List<MemberResponseDto>>.Ok(result);
        }

        public async Task<ApiResponse<MemberResponseDto>> UpdateRoleAsync(Guid projectId, Guid memberId, UpdateMemberRoleDto dto, string operatorUserId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null)
            {
                return ApiResponse<MemberResponseDto>.Fail("Không tìm thấy dự án");
            }

            // Kiểm tra quyền của người thực hiện
            var operatorMember = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == operatorUserId);

            if (operatorMember == null || (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Manager))
            {
                return ApiResponse<MemberResponseDto>.Fail("Bạn không có quyền quản lý thành viên trong dự án này");
            }

            var member = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.Id == memberId && m.ProjectId == projectId);

            if (member == null)
            {
                return ApiResponse<MemberResponseDto>.Fail("Không tìm thấy thành viên trong dự án");
            }

            // Không cho phép đổi role của Owner
            if (member.Role == MemberRole.Owner)
            {
                return ApiResponse<MemberResponseDto>.Fail("Không thể thay đổi vai trò của Owner");
            }

            // Nếu người thực hiện là Manager:
            // 1. Không được sửa role của Manager khác hoặc Owner
            // 2. Không được phong làm Manager hoặc Owner
            if (operatorMember.Role == MemberRole.Manager)
            {
                if (member.Role == MemberRole.Manager || member.Role == MemberRole.Owner)
                {
                    return ApiResponse<MemberResponseDto>.Fail("Manager không có quyền thay đổi vai trò của Manager khác hoặc Owner");
                }
                if (dto.Role == MemberRole.Manager || dto.Role == MemberRole.Owner)
                {
                    return ApiResponse<MemberResponseDto>.Fail("Manager không có quyền phong chức người khác lên Manager hoặc Owner");
                }
            }

            member.Role = dto.Role;
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Member '{DisplayName}' role updated to {Role} in project {ProjectId}",
                member.DisplayName, member.Role, projectId);

            return ApiResponse<MemberResponseDto>.Ok(MapToResponse(member), "Cập nhật vai trò thành công");
        }

        public async Task<ApiResponse<bool>> RemoveMemberAsync(Guid projectId, Guid memberId, string operatorUserId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null)
            {
                return ApiResponse<bool>.Fail("Không tìm thấy dự án");
            }

            // Kiểm tra quyền của người thực hiện
            var operatorMember = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == operatorUserId);

            if (operatorMember == null || (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Manager))
            {
                return ApiResponse<bool>.Fail("Bạn không có quyền quản lý thành viên trong dự án này");
            }

            var member = await _context.ProjectMembers
                .FirstOrDefaultAsync(m => m.Id == memberId && m.ProjectId == projectId);

            if (member == null)
            {
                return ApiResponse<bool>.Fail("Không tìm thấy thành viên trong dự án");
            }

            // Không cho phép xóa Owner
            if (member.Role == MemberRole.Owner)
            {
                return ApiResponse<bool>.Fail("Không thể xóa Owner khỏi dự án");
            }

            // Nếu người thực hiện là Manager, không được xóa Manager khác hoặc Owner
            if (operatorMember.Role == MemberRole.Manager && (member.Role == MemberRole.Manager || member.Role == MemberRole.Owner))
            {
                return ApiResponse<bool>.Fail("Manager không có quyền xóa Manager khác hoặc Owner khỏi dự án");
            }

            _context.ProjectMembers.Remove(member);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Member '{DisplayName}' removed from project {ProjectId}",
                member.DisplayName, projectId);

            return ApiResponse<bool>.Ok(true, "Xóa thành viên thành công");
        }

        private static MemberResponseDto MapToResponse(ProjectMember member)
        {
            return new MemberResponseDto
            {
                Id = member.Id,
                ProjectId = member.ProjectId,
                UserId = member.UserId,
                DisplayName = member.DisplayName,
                Email = member.Email,
                Role = member.Role.ToString(),
                JoinedAt = member.JoinedAt
            };
        }
    }
}
