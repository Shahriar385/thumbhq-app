/// User roles within the agency
enum UserRole {
  pending('pending', 'Pending'),
  manager('manager', 'Manager'),
  strategist('strategist', 'Strategist'),
  leadDesigner('lead_designer', 'Lead Designer'),
  coreDesigner('core_designer', 'Core Designer'),
  juniorDesigner('junior_designer', 'Junior Designer');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.pending,
    );
  }

  bool get isDesigner =>
      this == leadDesigner || this == coreDesigner || this == juniorDesigner;

  bool get isManager => this == manager;
  bool get isStrategist => this == strategist;
  bool get isPending => this == pending;
}

/// Project status
enum ProjectStatus {
  active('active', 'Active'),
  practice('practice', 'Practice'),
  completed('completed', 'Completed');

  const ProjectStatus(this.value, this.label);
  final String value;
  final String label;

  static ProjectStatus fromValue(String value) {
    return ProjectStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ProjectStatus.active,
    );
  }
}

/// Project approval status
enum ApprovalStatus {
  ongoing('ongoing', 'Ongoing'),
  needsApproval('needs_approval', 'Needs Approval'),
  approved('approved', 'Approved');

  const ApprovalStatus(this.value, this.label);
  final String value;
  final String label;

  static ApprovalStatus fromValue(String value) {
    return ApprovalStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ApprovalStatus.ongoing,
    );
  }
}

/// Assignment status for strategist/designer on a project
enum AssignmentStatus {
  assigned('assigned', 'Assigned'),
  submitted('submitted', 'Submitted'),
  revision('revision', 'Revision Requested');

  const AssignmentStatus(this.value, this.label);
  final String value;
  final String label;

  static AssignmentStatus fromValue(String value) {
    return AssignmentStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => AssignmentStatus.assigned,
    );
  }
}
