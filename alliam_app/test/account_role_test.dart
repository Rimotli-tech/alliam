import 'package:alliam_app/features/auth/domain/account_session.dart';
import 'package:alliam_app/features/organization/data/organization_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin uses the Admin entry and never exposes an active learner', () {
    const session = AccountSession(
      role: AccountRole.admin,
      ownerName: 'Rimotli',
      ownerCountry: 'Nigeria',
      schoolName: '',
      activeLearnerId: 'legacy-learner',
      learners: [
        LearnerProfile(
          id: 'legacy-learner',
          name: 'Legacy learner',
          grade: 'Grade 1',
          country: 'Nigeria',
          school: '',
          avatar: 'L',
        ),
      ],
    );

    expect(session.entryLocation, '/admin');
    expect(session.activeLearner, isNull);
    expect(session.firstName, 'Rimotli');
  });

  test('organization uses its dashboard and can manage learners', () {
    const session = AccountSession(
      role: AccountRole.organization,
      ownerName: 'Coach Ada',
      ownerCountry: 'Nigeria',
      schoolName: 'Alliam Academy',
      activeLearnerId: null,
      learners: [],
    );

    expect(session.entryLocation, '/organization');
    expect(session.organizationName, 'Alliam Academy');
    expect(session.managesLearners, isTrue);
  });

  test('organization membership permissions are explicit', () {
    const access = OrganizationAccess(
      organizationId: 'org-1',
      role: 'owner',
      permissions: {
        'manageLearners': true,
        'manageTeams': true,
        'manageCompetitions': true,
      },
    );

    expect(access.can('manageLearners'), isTrue);
    expect(access.can('manageMembers'), isFalse);
  });
}
