using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ProjectMemberService.Models
{
    public enum SprintStatus
    {
        Planning,
        Active,
        Completed
    }

    public class Sprint
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid ProjectId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Goal { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public SprintStatus Status { get; set; } = SprintStatus.Planning;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        [ForeignKey(nameof(ProjectId))]
        public Project Project { get; set; } = null!;
    }
}
