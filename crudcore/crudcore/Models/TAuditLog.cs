using System;
using System.Collections.Generic;

namespace crudcore.Models;

public partial class TAuditLog
{
    public int IdAuditLog { get; set; }

    public int? IdUser { get; set; }

    public string? AuditType { get; set; }

    public DateTime? AuditDate { get; set; }

    public string? UserName { get; set; }
}
