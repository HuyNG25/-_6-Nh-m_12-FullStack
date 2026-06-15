using System.ComponentModel.DataAnnotations;

namespace ProjectMemberService.Models
{
    public enum ProjectStatus
    {
        Active,
        Completed,
        Archived
    }

    public class Project
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string? Description { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [MaxLength(7)]
        public string? Color { get; set; }

        public ProjectStatus Status { get; set; } = ProjectStatus.Active;

        [Required]
        public string CreatedBy { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ICollection<ProjectMember> Members { get; set; } = new List<ProjectMember>();
        public ICollection<Sprint> Sprints { get; set; } = new List<Sprint>();
        public ICollection<Milestone> Milestones { get; set; } = new List<Milestone>();
    }
}
