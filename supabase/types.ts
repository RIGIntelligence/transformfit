export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      ai_adaptations: {
        Row: {
          adapted_plan: Json | null
          coaching_cue: string | null
          created_at: string
          error_message: string | null
          estimated_duration_minutes: number | null
          fatigue_index: number | null
          id: string
          latency_ms: number | null
          model_used: string | null
          narrative: Json | null
          readiness_delta: number | null
          readiness_score: number | null
          session_id: string | null
          status: string
          tokens_used: number | null
          trigger_type: string
          user_id: string
          volume_adjustment: string | null
          volume_trend: number | null
        }
        Insert: {
          adapted_plan?: Json | null
          coaching_cue?: string | null
          created_at?: string
          error_message?: string | null
          estimated_duration_minutes?: number | null
          fatigue_index?: number | null
          id?: string
          latency_ms?: number | null
          model_used?: string | null
          narrative?: Json | null
          readiness_delta?: number | null
          readiness_score?: number | null
          session_id?: string | null
          status?: string
          tokens_used?: number | null
          trigger_type?: string
          user_id: string
          volume_adjustment?: string | null
          volume_trend?: number | null
        }
        Update: {
          adapted_plan?: Json | null
          coaching_cue?: string | null
          created_at?: string
          error_message?: string | null
          estimated_duration_minutes?: number | null
          fatigue_index?: number | null
          id?: string
          latency_ms?: number | null
          model_used?: string | null
          narrative?: Json | null
          readiness_delta?: number | null
          readiness_score?: number | null
          session_id?: string | null
          status?: string
          tokens_used?: number | null
          trigger_type?: string
          user_id?: string
          volume_adjustment?: string | null
          volume_trend?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_adaptations_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_adaptations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_coach_messages: {
        Row: {
          client_user_id: string
          coach_id: string | null
          created_at: string
          id: string
          message_body: string
          message_type: string
          read_at: string | null
          sent_at: string | null
          status: string
        }
        Insert: {
          client_user_id: string
          coach_id?: string | null
          created_at?: string
          id?: string
          message_body?: string
          message_type?: string
          read_at?: string | null
          sent_at?: string | null
          status?: string
        }
        Update: {
          client_user_id?: string
          coach_id?: string | null
          created_at?: string
          id?: string
          message_body?: string
          message_type?: string
          read_at?: string | null
          sent_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_coach_messages_client_user_id_fkey"
            columns: ["client_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_readiness_results: {
        Row: {
          coaching_cue: string | null
          completed_at: string | null
          created_at: string
          explanation: string | null
          full_result: Json | null
          id: string
          mobility_flow: string[] | null
          plan_date: string
          readiness_log_id: string | null
          status: string
          suggested_session_type: string | null
          user_id: string
          verdict: string | null
        }
        Insert: {
          coaching_cue?: string | null
          completed_at?: string | null
          created_at?: string
          explanation?: string | null
          full_result?: Json | null
          id?: string
          mobility_flow?: string[] | null
          plan_date?: string
          readiness_log_id?: string | null
          status?: string
          suggested_session_type?: string | null
          user_id: string
          verdict?: string | null
        }
        Update: {
          coaching_cue?: string | null
          completed_at?: string | null
          created_at?: string
          explanation?: string | null
          full_result?: Json | null
          id?: string
          mobility_flow?: string[] | null
          plan_date?: string
          readiness_log_id?: string | null
          status?: string
          suggested_session_type?: string | null
          user_id?: string
          verdict?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_readiness_results_readiness_log_id_fkey"
            columns: ["readiness_log_id"]
            isOneToOne: false
            referencedRelation: "daily_readiness_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_readiness_results_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      coach_alerts: {
        Row: {
          action_suggestion: string | null
          alert_type: string
          client_id: string
          coach_id: string | null
          created_at: string
          data: Json | null
          description: string
          id: string
          is_read: boolean
          is_resolved: boolean
          resolved_at: string | null
          severity: string
          title: string
        }
        Insert: {
          action_suggestion?: string | null
          alert_type?: string
          client_id: string
          coach_id?: string | null
          created_at?: string
          data?: Json | null
          description?: string
          id?: string
          is_read?: boolean
          is_resolved?: boolean
          resolved_at?: string | null
          severity?: string
          title: string
        }
        Update: {
          action_suggestion?: string | null
          alert_type?: string
          client_id?: string
          coach_id?: string | null
          created_at?: string
          data?: Json | null
          description?: string
          id?: string
          is_read?: boolean
          is_resolved?: boolean
          resolved_at?: string | null
          severity?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_alerts_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      coach_memory: {
        Row: {
          confidence: number
          created_at: string
          id: string
          is_active: boolean
          key: string
          last_referenced_at: string | null
          memory_type: string
          source: string
          source_message_id: string | null
          updated_at: string
          user_id: string
          value: string
        }
        Insert: {
          confidence?: number
          created_at?: string
          id?: string
          is_active?: boolean
          key: string
          last_referenced_at?: string | null
          memory_type: string
          source?: string
          source_message_id?: string | null
          updated_at?: string
          user_id: string
          value: string
        }
        Update: {
          confidence?: number
          created_at?: string
          id?: string
          is_active?: boolean
          key?: string
          last_referenced_at?: string | null
          memory_type?: string
          source?: string
          source_message_id?: string | null
          updated_at?: string
          user_id?: string
          value?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_memory_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      daily_readiness_logs: {
        Row: {
          created_at: string
          date: string | null
          energy_level: number
          hrv: number | null
          id: string
          logged_at: string
          mood: string | null
          readiness_score: number | null
          sleep_quality: number
          soreness_level: number | null
          soreness_map: string[]
          source: string
          strain: number
          stress_level: number | null
          user_id: string
        }
        Insert: {
          created_at?: string
          date?: string | null
          energy_level?: number
          hrv?: number | null
          id?: string
          logged_at?: string
          mood?: string | null
          readiness_score?: number | null
          sleep_quality?: number
          soreness_level?: number | null
          soreness_map?: string[]
          source?: string
          strain?: number
          stress_level?: number | null
          user_id: string
        }
        Update: {
          created_at?: string
          date?: string | null
          energy_level?: number
          hrv?: number | null
          id?: string
          logged_at?: string
          mood?: string | null
          readiness_score?: number | null
          sleep_quality?: number
          soreness_level?: number | null
          soreness_map?: string[]
          source?: string
          strain?: number
          stress_level?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "daily_readiness_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      equipment: {
        Row: {
          created_at: string
          icon: string
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          icon?: string
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          icon?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      exercises: {
        Row: {
          created_at: string
          cue_1: string | null
          cue_2: string | null
          cue_3: string | null
          default_reps: number | null
          default_rest_seconds: number | null
          default_rpe_target: number | null
          default_sets: number | null
          difficulty: string
          equipment: string
          equipment_ids: string[] | null
          equipment_type_id: string | null
          id: string
          instructions: string | null
          is_compound: boolean
          movement_pattern: string | null
          muscle_group: string
          muscle_group_id: string | null
          name: string
          popular: boolean
          video_url: string | null
        }
        Insert: {
          created_at?: string
          cue_1?: string | null
          cue_2?: string | null
          cue_3?: string | null
          default_reps?: number | null
          default_rest_seconds?: number | null
          default_rpe_target?: number | null
          default_sets?: number | null
          difficulty?: string
          equipment?: string
          equipment_ids?: string[] | null
          equipment_type_id?: string | null
          id: string
          instructions?: string | null
          is_compound?: boolean
          movement_pattern?: string | null
          muscle_group: string
          muscle_group_id?: string | null
          name: string
          popular?: boolean
          video_url?: string | null
        }
        Update: {
          created_at?: string
          cue_1?: string | null
          cue_2?: string | null
          cue_3?: string | null
          default_reps?: number | null
          default_rest_seconds?: number | null
          default_rpe_target?: number | null
          default_sets?: number | null
          difficulty?: string
          equipment?: string
          equipment_ids?: string[] | null
          equipment_type_id?: string | null
          id?: string
          instructions?: string | null
          is_compound?: boolean
          movement_pattern?: string | null
          muscle_group?: string
          muscle_group_id?: string | null
          name?: string
          popular?: boolean
          video_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "exercises_equipment_type_id_fkey"
            columns: ["equipment_type_id"]
            isOneToOne: false
            referencedRelation: "equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "exercises_muscle_group_id_fkey"
            columns: ["muscle_group_id"]
            isOneToOne: false
            referencedRelation: "muscle_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      muscle_groups: {
        Row: {
          category: string
          created_at: string
          icon: string
          id: string
          name: string
        }
        Insert: {
          category?: string
          created_at?: string
          icon?: string
          id?: string
          name: string
        }
        Update: {
          category?: string
          created_at?: string
          icon?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          age: number | null
          barriers: string[] | null
          biological_sex: string | null
          coach_day_number: number
          coach_persona: string | null
          created_at: string
          cycle_tracking_enabled: boolean
          daily_calories_target: number | null
          daily_carbs_target: number | null
          daily_fat_target: number | null
          daily_protein_target: number | null
          display_name: string | null
          equipment: string[] | null
          experience_level: string | null
          fatigue_debt: number | null
          fitness_level: string | null
          glp1_dose: string | null
          glp1_enabled: boolean
          glp1_injection_days: string[] | null
          glp1_medication: string | null
          glp1_side_effects: string[] | null
          glp1_start_date: string | null
          goal: string | null
          height_cm: number | null
          id: string
          identity_anchor: string | null
          last_active_at: string | null
          last_workout_date: string | null
          limitations: string[] | null
          movement_screen_scores: Json | null
          next_game_date: string | null
          onboarding_completed: boolean
          payment_failed: boolean
          referral_code: string | null
          referrals_count: number
          referred_by: string | null
          response_profile: string | null
          schedule: Json | null
          season_phase: string | null
          sport: string | null
          streak_current: number
          streak_longest: number
          stripe_customer_id: string | null
          stripe_subscription_id: string | null
          subscription_status: string
          training_days_per_week: number | null
          weight_kg: number | null
          weight_unit: string | null
        }
        Insert: {
          age?: number | null
          barriers?: string[] | null
          biological_sex?: string | null
          coach_day_number?: number
          coach_persona?: string | null
          created_at?: string
          cycle_tracking_enabled?: boolean
          daily_calories_target?: number | null
          daily_carbs_target?: number | null
          daily_fat_target?: number | null
          daily_protein_target?: number | null
          display_name?: string | null
          equipment?: string[] | null
          experience_level?: string | null
          fatigue_debt?: number | null
          fitness_level?: string | null
          glp1_dose?: string | null
          glp1_enabled?: boolean
          glp1_injection_days?: string[] | null
          glp1_medication?: string | null
          glp1_side_effects?: string[] | null
          glp1_start_date?: string | null
          goal?: string | null
          height_cm?: number | null
          id: string
          identity_anchor?: string | null
          last_active_at?: string | null
          last_workout_date?: string | null
          limitations?: string[] | null
          movement_screen_scores?: Json | null
          next_game_date?: string | null
          onboarding_completed?: boolean
          payment_failed?: boolean
          referral_code?: string | null
          referrals_count?: number
          referred_by?: string | null
          response_profile?: string | null
          schedule?: Json | null
          season_phase?: string | null
          sport?: string | null
          streak_current?: number
          streak_longest?: number
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_status?: string
          training_days_per_week?: number | null
          weight_kg?: number | null
          weight_unit?: string | null
        }
        Update: {
          age?: number | null
          barriers?: string[] | null
          biological_sex?: string | null
          coach_day_number?: number
          coach_persona?: string | null
          created_at?: string
          cycle_tracking_enabled?: boolean
          daily_calories_target?: number | null
          daily_carbs_target?: number | null
          daily_fat_target?: number | null
          daily_protein_target?: number | null
          display_name?: string | null
          equipment?: string[] | null
          experience_level?: string | null
          fatigue_debt?: number | null
          fitness_level?: string | null
          glp1_dose?: string | null
          glp1_enabled?: boolean
          glp1_injection_days?: string[] | null
          glp1_medication?: string | null
          glp1_side_effects?: string[] | null
          glp1_start_date?: string | null
          goal?: string | null
          height_cm?: number | null
          id?: string
          identity_anchor?: string | null
          last_active_at?: string | null
          last_workout_date?: string | null
          limitations?: string[] | null
          movement_screen_scores?: Json | null
          next_game_date?: string | null
          onboarding_completed?: boolean
          payment_failed?: boolean
          referral_code?: string | null
          referrals_count?: number
          referred_by?: string | null
          response_profile?: string | null
          schedule?: Json | null
          season_phase?: string | null
          sport?: string | null
          streak_current?: number
          streak_longest?: number
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_status?: string
          training_days_per_week?: number | null
          weight_kg?: number | null
          weight_unit?: string | null
        }
        Relationships: []
      }
      program_days: {
        Row: {
          created_at: string
          day_number: number
          description: string | null
          duration_minutes: number | null
          focus: string | null
          id: string
          muscle_groups: string[] | null
          program_id: string
          title: string | null
          week_number: number
        }
        Insert: {
          created_at?: string
          day_number: number
          description?: string | null
          duration_minutes?: number | null
          focus?: string | null
          id?: string
          muscle_groups?: string[] | null
          program_id: string
          title?: string | null
          week_number: number
        }
        Update: {
          created_at?: string
          day_number?: number
          description?: string | null
          duration_minutes?: number | null
          focus?: string | null
          id?: string
          muscle_groups?: string[] | null
          program_id?: string
          title?: string | null
          week_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "program_days_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_exercises: {
        Row: {
          created_at: string
          exercise_id: string | null
          exercise_name: string
          id: string
          notes: string | null
          program_day_id: string
          progression_type: string | null
          rationale: string | null
          rep_range: string
          reps_max: number | null
          reps_min: number | null
          rest_seconds: number | null
          rpe_target: number | null
          sets: number
          sort_order: number
          weight_increment_kg: number | null
        }
        Insert: {
          created_at?: string
          exercise_id?: string | null
          exercise_name: string
          id?: string
          notes?: string | null
          program_day_id: string
          progression_type?: string | null
          rationale?: string | null
          rep_range?: string
          reps_max?: number | null
          reps_min?: number | null
          rest_seconds?: number | null
          rpe_target?: number | null
          sets?: number
          sort_order?: number
          weight_increment_kg?: number | null
        }
        Update: {
          created_at?: string
          exercise_id?: string | null
          exercise_name?: string
          id?: string
          notes?: string | null
          program_day_id?: string
          progression_type?: string | null
          rationale?: string | null
          rep_range?: string
          reps_max?: number | null
          reps_min?: number | null
          rest_seconds?: number | null
          rpe_target?: number | null
          sets?: number
          sort_order?: number
          weight_increment_kg?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "program_exercises_exercise_id_fkey"
            columns: ["exercise_id"]
            isOneToOne: false
            referencedRelation: "exercises"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_exercises_program_day_id_fkey"
            columns: ["program_day_id"]
            isOneToOne: false
            referencedRelation: "program_days"
            referencedColumns: ["id"]
          },
        ]
      }
      program_session_logs: {
        Row: {
          completed_at: string
          created_at: string
          id: string
          notes: string | null
          program_day_id: string
          rating: number | null
          readiness_score: number | null
          user_id: string
          user_program_id: string
        }
        Insert: {
          completed_at?: string
          created_at?: string
          id?: string
          notes?: string | null
          program_day_id: string
          rating?: number | null
          readiness_score?: number | null
          user_id: string
          user_program_id: string
        }
        Update: {
          completed_at?: string
          created_at?: string
          id?: string
          notes?: string | null
          program_day_id?: string
          rating?: number | null
          readiness_score?: number | null
          user_id?: string
          user_program_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_session_logs_program_day_id_fkey"
            columns: ["program_day_id"]
            isOneToOne: false
            referencedRelation: "program_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_session_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_session_logs_user_program_id_fkey"
            columns: ["user_program_id"]
            isOneToOne: false
            referencedRelation: "user_programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_weeks: {
        Row: {
          created_at: string
          focus_note: string | null
          id: string
          intensity_modifier: number
          phase: string
          program_id: string
          volume_modifier: number
          week_number: number
        }
        Insert: {
          created_at?: string
          focus_note?: string | null
          id?: string
          intensity_modifier?: number
          phase?: string
          program_id: string
          volume_modifier?: number
          week_number: number
        }
        Update: {
          created_at?: string
          focus_note?: string | null
          id?: string
          intensity_modifier?: number
          phase?: string
          program_id?: string
          volume_modifier?: number
          week_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "program_weeks_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      programs: {
        Row: {
          brand_color: string | null
          created_at: string
          created_by: string | null
          deload_frequency_weeks: number | null
          description: string | null
          duration_weeks: number
          goal: string | null
          id: string
          influences: string[] | null
          is_featured: boolean | null
          is_public: boolean
          level: string
          methodology: string | null
          methodology_notes: string | null
          phases: Json | null
          sessions_per_week: number
          title: string
          training_age_months_min: number | null
        }
        Insert: {
          brand_color?: string | null
          created_at?: string
          created_by?: string | null
          deload_frequency_weeks?: number | null
          description?: string | null
          duration_weeks?: number
          goal?: string | null
          id?: string
          influences?: string[] | null
          is_featured?: boolean | null
          is_public?: boolean
          level?: string
          methodology?: string | null
          methodology_notes?: string | null
          phases?: Json | null
          sessions_per_week?: number
          title: string
          training_age_months_min?: number | null
        }
        Update: {
          brand_color?: string | null
          created_at?: string
          created_by?: string | null
          deload_frequency_weeks?: number | null
          description?: string | null
          duration_weeks?: number
          goal?: string | null
          id?: string
          influences?: string[] | null
          is_featured?: boolean | null
          is_public?: boolean
          level?: string
          methodology?: string | null
          methodology_notes?: string | null
          phases?: Json | null
          sessions_per_week?: number
          title?: string
          training_age_months_min?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "programs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      progression_records: {
        Row: {
          exercise_id: string | null
          hit_all_reps: boolean
          id: string
          program_exercise_id: string | null
          ready_to_progress: boolean
          recorded_at: string
          reps_completed: number[]
          rpe: number | null
          session_id: string | null
          user_id: string
          weight: number
        }
        Insert: {
          exercise_id?: string | null
          hit_all_reps?: boolean
          id?: string
          program_exercise_id?: string | null
          ready_to_progress?: boolean
          recorded_at?: string
          reps_completed?: number[]
          rpe?: number | null
          session_id?: string | null
          user_id: string
          weight?: number
        }
        Update: {
          exercise_id?: string | null
          hit_all_reps?: boolean
          id?: string
          program_exercise_id?: string | null
          ready_to_progress?: boolean
          recorded_at?: string
          reps_completed?: number[]
          rpe?: number | null
          session_id?: string | null
          user_id?: string
          weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "progression_records_exercise_id_fkey"
            columns: ["exercise_id"]
            isOneToOne: false
            referencedRelation: "exercises"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "progression_records_program_exercise_id_fkey"
            columns: ["program_exercise_id"]
            isOneToOne: false
            referencedRelation: "program_exercises"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "progression_records_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "progression_records_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      recovery_day_logs: {
        Row: {
          activities: string[]
          created_at: string
          id: string
          logged_at: string
          notes: string | null
          readiness_score: number | null
          user_id: string
        }
        Insert: {
          activities?: string[]
          created_at?: string
          id?: string
          logged_at?: string
          notes?: string | null
          readiness_score?: number | null
          user_id: string
        }
        Update: {
          activities?: string[]
          created_at?: string
          id?: string
          logged_at?: string
          notes?: string | null
          readiness_score?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recovery_day_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      recovery_logs: {
        Row: {
          adjusted_volume: number | null
          created_at: string
          hrv: number
          id: string
          logged_at: string
          muscle_soreness: number
          nutrition_compliance: number
          readiness_score: number | null
          recommendation: string | null
          recovery_tips: string[] | null
          resting_hr: number
          sleep_hours: number
          sleep_score: number
          stress_level: number
          user_id: string
        }
        Insert: {
          adjusted_volume?: number | null
          created_at?: string
          hrv?: number
          id?: string
          logged_at?: string
          muscle_soreness?: number
          nutrition_compliance?: number
          readiness_score?: number | null
          recommendation?: string | null
          recovery_tips?: string[] | null
          resting_hr?: number
          sleep_hours?: number
          sleep_score?: number
          stress_level?: number
          user_id: string
        }
        Update: {
          adjusted_volume?: number | null
          created_at?: string
          hrv?: number
          id?: string
          logged_at?: string
          muscle_soreness?: number
          nutrition_compliance?: number
          readiness_score?: number | null
          recommendation?: string | null
          recovery_tips?: string[] | null
          resting_hr?: number
          sleep_hours?: number
          sleep_score?: number
          stress_level?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recovery_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sessions: {
        Row: {
          adaptations_made: number | null
          completed_at: string | null
          created_at: string
          id: string
          pre_energy: number | null
          pre_hrv: number | null
          pre_sleep: number | null
          pre_strain: number | null
          readiness_score: number | null
          session_summary: string | null
          session_type: string | null
          started_at: string | null
          status: string
          total_volume_kg: number | null
          user_id: string
        }
        Insert: {
          adaptations_made?: number | null
          completed_at?: string | null
          created_at?: string
          id?: string
          pre_energy?: number | null
          pre_hrv?: number | null
          pre_sleep?: number | null
          pre_strain?: number | null
          readiness_score?: number | null
          session_summary?: string | null
          session_type?: string | null
          started_at?: string | null
          status?: string
          total_volume_kg?: number | null
          user_id: string
        }
        Update: {
          adaptations_made?: number | null
          completed_at?: string | null
          created_at?: string
          id?: string
          pre_energy?: number | null
          pre_hrv?: number | null
          pre_sleep?: number | null
          pre_strain?: number | null
          readiness_score?: number | null
          session_summary?: string | null
          session_type?: string | null
          started_at?: string | null
          status?: string
          total_volume_kg?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      set_logs: {
        Row: {
          actual_reps: number | null
          actual_weight: number | null
          exercise_name: string
          id: string
          is_compound: boolean | null
          logged_at: string
          rpe: number | null
          session_id: string
          set_number: number | null
          target_reps: string | null
          target_weight: number | null
          user_id: string
        }
        Insert: {
          actual_reps?: number | null
          actual_weight?: number | null
          exercise_name: string
          id?: string
          is_compound?: boolean | null
          logged_at?: string
          rpe?: number | null
          session_id: string
          set_number?: number | null
          target_reps?: string | null
          target_weight?: number | null
          user_id: string
        }
        Update: {
          actual_reps?: number | null
          actual_weight?: number | null
          exercise_name?: string
          id?: string
          is_compound?: boolean | null
          logged_at?: string
          rpe?: number | null
          session_id?: string
          set_number?: number | null
          target_reps?: string | null
          target_weight?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "set_logs_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "set_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      streaks: {
        Row: {
          broken_at: string | null
          created_at: string
          current_count: number
          freeze_count: number
          freezes_used: number
          id: string
          is_active: boolean
          last_activity_date: string | null
          last_date: string | null
          longest_count: number
          started_at: string | null
          streak_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          broken_at?: string | null
          created_at?: string
          current_count?: number
          freeze_count?: number
          freezes_used?: number
          id?: string
          is_active?: boolean
          last_activity_date?: string | null
          last_date?: string | null
          longest_count?: number
          started_at?: string | null
          streak_type: string
          updated_at?: string
          user_id: string
        }
        Update: {
          broken_at?: string | null
          created_at?: string
          current_count?: number
          freeze_count?: number
          freezes_used?: number
          id?: string
          is_active?: boolean
          last_activity_date?: string | null
          last_date?: string | null
          longest_count?: number
          started_at?: string | null
          streak_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "streaks_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_programs: {
        Row: {
          completed_at: string | null
          created_at: string
          current_day: number
          current_phase: string
          current_week: number
          id: string
          notes: string | null
          program_id: string
          settings: Json | null
          started_at: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          current_day?: number
          current_phase?: string
          current_week?: number
          id?: string
          notes?: string | null
          program_id: string
          settings?: Json | null
          started_at?: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          current_day?: number
          current_phase?: string
          current_week?: number
          id?: string
          notes?: string | null
          program_id?: string
          settings?: Json | null
          started_at?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_programs_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_programs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_subscriptions: {
        Row: {
          created_at: string
          expires_at: string | null
          id: string
          started_at: string
          status: string
          stripe_customer_id: string | null
          stripe_subscription_id: string | null
          tier: Database["public"]["Enums"]["subscription_tier"]
          trial_ends_at: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          expires_at?: string | null
          id?: string
          started_at?: string
          status?: string
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          tier?: Database["public"]["Enums"]["subscription_tier"]
          trial_ends_at?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          expires_at?: string | null
          id?: string
          started_at?: string
          status?: string
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          tier?: Database["public"]["Enums"]["subscription_tier"]
          trial_ends_at?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      subscription_tier: "free" | "pro" | "coach"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      subscription_tier: ["free", "pro", "coach"],
    },
  },
} as const
