import '../models/models.dart';

abstract class VisitRepository {
  Future<List<Visit>> getVisits();
  Future<Visit?> getVisit(String id);
  Future<Visit> createVisit(Visit visit);
  Future<Visit> updateVisit(Visit visit);
  Future<void> deleteVisit(String id);
  Future<List<Visit>> getRecentVisits({int limit = 10});
  Future<List<Visit>> getVisitsWithDoctor(String doctorName);
  Future<List<Visit>> getVisitsForDateRange(DateTime start, DateTime end);
  Future<Visit?> getLatestVisit();
  Stream<List<Visit>> watchVisits();
  Stream<List<Visit>> watchRecentVisits({int limit = 10});
}
