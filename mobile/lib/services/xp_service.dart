import '../database/db_helper.dart';

class XpService {
  static const Map<String, int> xpRewards = {
    'complete_task': 10,
    'habit_checkin': 5,
    'complete_subtask': 5,
    'complete_milestone': 25,
    'complete_goal': 100,
    'pomodoro_cycle': 15,
    'log_mood': 3,
    'log_water': 3,
    'log_sleep': 3,
    'log_exercise': 3,
    'create_flashcard_deck': 10,
    'study_flashcards': 8,
    'log_attendance': 2,
    'weekly_review': 20,
    'flashcard_easy': 2,
    'flashcard_hard': 1,
  };

  static Future<List<String>> award(String reason) async {
    final amount = xpRewards[reason] ?? 5;
    return DbHelper.instance.awardXp(amount, reason);
  }

  static List<String> getLevelNames(String stream) {
    switch (stream) {
      case 'engineering':
        return ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate',
            'Engineer', 'Architect', 'Innovator', 'Pioneer', 'Legend'];
      case 'medical':
        return ['Intern', 'Resident', 'Registrar', 'Fellow', 'Consultant',
            'Specialist', 'Professor', 'Surgeon', 'Chief', 'Lifesaver'];
      case 'law':
        return ['Clerk', 'Paralegal', 'Associate', 'Solicitor', 'Barrister',
            'Advocate', 'Senior Counsel', 'QC', 'Judge', 'Justice'];
      case 'competitive':
        return ['Aspirant', 'Beginner', 'Learner', 'Practitioner', 'Contender',
            'Qualifier', 'Ranker', 'Achiever', 'Topper', 'Legend'];
      default:
        return List.generate(10, (i) => 'Level ${i + 1}');
    }
  }

  static String getLevelName(String stream, int level) {
    final names = getLevelNames(stream);
    final idx = (level - 1).clamp(0, names.length - 1);
    return names[idx];
  }
}
