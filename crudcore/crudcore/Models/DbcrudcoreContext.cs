using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace crudcore.Models;

public partial class DbcrudcoreContext : DbContext
{
    public DbcrudcoreContext()
    {
    }

    public DbcrudcoreContext(DbContextOptions<DbcrudcoreContext> options)
        : base(options)
    {
    }

    public virtual DbSet<TAuditLog> TAuditLogs { get; set; }

    public virtual DbSet<TStatus> TStatuses { get; set; }

    public virtual DbSet<TUser> TUsers { get; set; }

   // protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
//#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
  //     => optionsBuilder.UseSqlServer("server=DESKTOP-EU85N82; database=DBCRUDCORE; integrated security=true; TrustServerCertificate=Yes");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TAuditLog>(entity =>
        {
            entity.HasKey(e => e.IdAuditLog).HasName("PK__T_AUDIT___6F09EE01BBDD2ED6");

            entity.ToTable("T_AUDIT_LOG");

            entity.Property(e => e.AuditDate).HasColumnType("datetime");
            entity.Property(e => e.AuditType)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.UserName)
                .HasMaxLength(100)
                .IsUnicode(false);
        });

        modelBuilder.Entity<TStatus>(entity =>
        {
            entity.HasKey(e => e.IdStatus).HasName("PK__T_STATUS__B450643A685D365B");

            entity.ToTable("T_STATUS");

            entity.Property(e => e.DateCreation).HasColumnType("datetime");
            entity.Property(e => e.DateModification).HasColumnType("datetime");
            entity.Property(e => e.StatusDescription)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.StatusName)
                .HasMaxLength(10)
                .IsUnicode(false);
            entity.Property(e => e.UserCreation)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.UserModification)
                .HasMaxLength(100)
                .IsUnicode(false);
        });

        modelBuilder.Entity<TUser>(entity =>
        {
            entity.HasKey(e => e.IdUser).HasName("PK__T_USERS__B7C9263888BBD2EE");

            entity.ToTable("T_USERS");

            entity.HasIndex(e => e.Email, "UQ__T_USERS__A9D105343170D76C").IsUnique();

            entity.Property(e => e.DateCreation).HasColumnType("datetime");
            entity.Property(e => e.DateModification).HasColumnType("datetime");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.FirstName)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.LastName)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.Pass)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.UserCreation)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.UserModification)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.Username)
                .HasMaxLength(100)
                .IsUnicode(false);

            entity.HasOne(d => d.IdStatusNavigation).WithMany(p => p.TUsers)
                .HasForeignKey(d => d.IdStatus)
                .HasConstraintName("FK__T_USERS__IdStatu__3B75D760");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
