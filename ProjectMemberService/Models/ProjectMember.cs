using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ProjectMemberService.Models
{
    public enum MemberRole
    {
        Owner,
        Manager,
        Member,
        Viewer
    }

    public class ProjectMember
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid ProjectId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [MaxLength(200)]
        public string DisplayName { get; set; } = string.Empty;

        [MaxLength(300)]
        public string? Email { get; set; }

        public MemberRole Role { get; set; } = MemberRole.Member;

        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        [ForeignKey(nameof(ProjectId))]
        public Project Project { get; set; } = null!;
    }
}
