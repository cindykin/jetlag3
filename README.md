*AG 1*
Kerjakan Phase 1 dari 06_CURRENT_STATE.md — hilangkan duplicate schedule 
domain model (ActivityType/ActivityItem/TimelineSection di ScheduleView.swift), 
dan pastikan ScheduleView tidak lagi bergantung ke MockSchedule.sections.

udah = ScheduleView sekarang render dari trip.blocks (bukan MockSchedule lagi), dan BlockType sudah 8 tipe sesuai spec


*CODEX 1*
Hilangkan singleton AppState.shared. Buat instance AppState di-inject 
lewat .environmentObject() dari root ByeJetLagApp, semua View yang sebelumnya 
akses AppState.shared ganti jadi @EnvironmentObject.
