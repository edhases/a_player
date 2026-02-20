part of 'home_bloc.dart';

// Needs HomeSection definition
// Usually HomeSection is an entity.
// Since this is a 'part of' file, it shares imports from home_bloc.dart.
// Let's verify home_bloc.dart imports HomeSection.
// home_bloc.dart has: import '../../../../domain/entities/home_section.dart';
// So it SHOULD be visible.
// However, if the error persists, it might be that 'part of' directive is slightly finicky or the file wasn't saved/compiled correctly.
// Let's explicitly check home_bloc.dart imports again.
// Wait, 'HomeSection' isn't a type error in home_state.dart suggests it's NOT visible.
// This happens if home_bloc.dart doesn't have the import OR if there is a syntax error preventing the part relationship.
// Let's try adding the import here directly just in case, but 'part of' files usually don't have imports (though they can).
// BETTER: Ensure home_bloc.dart has the import.
// I will check home_bloc.dart content again or just re-add it there if missing.
// Actually I see I wrote home_bloc.dart in step 282 and it HAD the import.
// Maybe the previous `part of` syntax was wrong?
// home_bloc.dart: part 'home_state.dart';
// home_state.dart: part of 'home_bloc.dart';
// This looks correct.
// EXCEPT: generic type alias or something?
// Let's re-read home_bloc.dart to be sure.

/// @deprecated Use [BlocStatus] instead
typedef HomeStatus = BlocStatus;

class HomeState extends Equatable {
  final BlocStatus status;
  final List<HomeSection> sections;
  final String? errorMessage;

  const HomeState({
    this.status = BlocStatus.initial,
    this.sections = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    BlocStatus? status,
    List<HomeSection>? sections,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      sections: sections ?? this.sections,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sections, errorMessage];
}
