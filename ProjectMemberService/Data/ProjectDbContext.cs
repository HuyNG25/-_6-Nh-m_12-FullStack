using Microsoft.EntityFrameworkCore;
using ProjectMemberService.Models;

namespace ProjectMemberService.Data
{
    public class ProjectDbContext : DbContext
    {
        public ProjectDbContext(DbContextOptions<ProjectDbContext> options) : base(options) { }

        public DbSet<Project> Projects => Set<Project>();
        public DbSet<ProjectMember> ProjectMembers => Set<ProjectMember>();
        public DbSet<Sprint> Sprints => Set<Sprint>();
        public DbSet<Milestone> Milestones => Set<Milestone>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Project
            modelBuilder.Entity<Project>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
                entity.Property(e => e.Description).HasMaxLength(2000);
                entity.Property(e => e.Color).HasMaxLength(7);
                entity.Property(e => e.CreatedBy).IsRequired();
                entity.Property(e => e.Status).HasConversion<string>();
            });

            // ProjectMember
            modelBuilder.Entity<ProjectMember>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.UserId).IsRequired();
                entity.Property(e => e.DisplayName).HasMaxLength(200);
                entity.Property(e => e.Email).HasMaxLength(300);
                entity.Property(e => e.Role).HasConversion<string>();

                entity.HasOne(e => e.Project)
                      .WithMany(p => p.Members)
                      .HasForeignKey(e => e.ProjectId)
                      .OnDelete(DeleteBehavior.Cascade);

                // Mỗi user chỉ được thêm 1 lần vào project
                entity.HasIndex(e => new { e.ProjectId, e.UserId }).IsUnique();
            });

            // Sprint
            modelBuilder.Entity<Sprint>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
                entity.Property(e => e.Goal).HasMaxLength(1000);
                entity.Property(e => e.Status).HasConversion<string>();

                entity.HasOne(e => e.Project)
                      .WithMany(p => p.Sprints)
                      .HasForeignKey(e => e.ProjectId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            // Milestone
            modelBuilder.Entity<Milestone>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
                entity.Property(e => e.Description).HasMaxLength(1000);

                entity.HasOne(e => e.Project)
                      .WithMany(p => p.Milestones)
                      .HasForeignKey(e => e.ProjectId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
