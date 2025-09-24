import 'package:flutter/foundation.dart';

/// Manages the state and behavior of the voting panel
class VotingPanelController extends ChangeNotifier {
  bool _isOpen = false;
  String? _selectedValue;
  bool _canVote = false;
  bool _hasVoted = false;
  String _roundStatus = 'pending';

  bool get isOpen => _isOpen;
  String? get selectedValue => _selectedValue;
  bool get canVote => _canVote;
  bool get hasVoted => _hasVoted;
  String get roundStatus => _roundStatus;

  /// Opens the voting panel when voting starts
  void openPanel() {
    if (!_isOpen) {
      _isOpen = true;
      _canVote = true;
      notifyListeners();
    }
  }

  /// Closes the voting panel
  void closePanel() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Updates the selected vote value
  void updateSelectedValue(String? value) {
    _selectedValue = value;
    notifyListeners();
  }

  /// Marks that the user has voted and closes the panel
  void markAsVoted(String value) {
    _selectedValue = value;
    _hasVoted = true;
    _canVote = false;
    closePanel();
  }

  /// Updates the round status and manages panel state accordingly
  void updateRoundStatus(String status, {bool userHasVoted = false}) {
    final previousStatus = _roundStatus;
    _roundStatus = status;
    _hasVoted = userHasVoted;

    switch (status) {
      case 'pending':
        _reset();
        break;
      case 'voting':
        if (previousStatus != 'voting') {
          // New voting round started - open panel for everyone
          _canVote = !_hasVoted;
          openPanel();
        } else if (!_hasVoted) {
          // Still in voting phase and user hasn't voted - keep panel accessible
          _canVote = true;
        }
        break;
      case 'revealed':
        // Close panel immediately when results are revealed
        _canVote = false;
        closePanel();
        break;
    }

    notifyListeners();
  }

  /// Resets the controller state for a new round
  void _reset() {
    _isOpen = false;
    _selectedValue = null;
    _canVote = false;
    _hasVoted = false;
    notifyListeners();
  }

  /// Allows users to reopen the panel if they haven't voted and round is still in voting phase
  bool canReopenPanel() {
    return _roundStatus == 'voting' && !_hasVoted;
  }

  /// Reopens the panel if conditions are met
  void reopenPanel() {
    if (canReopenPanel()) {
      openPanel();
    }
  }
}
