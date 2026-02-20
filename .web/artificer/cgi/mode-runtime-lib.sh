#!/bin/sh

mr_runtime_root() {
  printf '%s' "$mode_runtime_root"
}

mr_modes_dir() {
  printf '%s/modes' "$(mr_runtime_root)"
}

mr_skills_dir() {
  printf '%s/skills' "$(mr_runtime_root)"
}

mr_bus_dir() {
  printf '%s/invocation-bus' "$(mr_runtime_root)"
}

mr_dashboard_dir() {
  printf '%s/dashboard' "$(mr_runtime_root)"
}

mr_scheduler_dir() {
  printf '%s/scheduler' "$(mr_runtime_root)"
}

mr_telemetry_dir() {
  printf '%s/telemetry' "$(mr_runtime_root)"
}

mr_interrupts_dir() {
  printf '%s/interrupts' "$(mr_runtime_root)"
}

mr_scheduler_state_file() {
  printf '%s/state.env' "$(mr_scheduler_dir)"
}

mr_now_epoch() {
  date +%s 2>/dev/null || printf '0'
}

mr_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date
}

mr_sanitize_inline() {
  printf '%s' "$1" | tr '\n\r' '  ' | sed 's/[[:space:]]\+/ /g;s/^ //;s/ $//'
}

mr_bool_norm() {
  value=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$value" in
    1|true|yes|on|enabled)
      printf '%s' "1"
      ;;
    *)
      printf '%s' "0"
      ;;
  esac
}

mr_positive_int_or() {
  value=$(trim "$1")
  fallback=$2
  case "$value" in
    ""|*[!0-9]*)
      printf '%s' "$fallback"
      ;;
    *)
      if [ "$value" -le 0 ]; then
        printf '%s' "$fallback"
      else
        printf '%s' "$value"
      fi
      ;;
  esac
}

mr_mode_dir_for() {
  mode_id=$1
  printf '%s/%s' "$(mr_modes_dir)" "$mode_id"
}

mr_skill_dir_for() {
  skill_id=$1
  printf '%s/%s' "$(mr_skills_dir)" "$skill_id"
}

mr_mode_manifest_file() {
  mode_id=$1
  printf '%s/manifest.env' "$(mr_mode_dir_for "$mode_id")"
}

mr_mode_state_file() {
  mode_id=$1
  printf '%s/state.env' "$(mr_mode_dir_for "$mode_id")"
}

mr_mode_policy_file() {
  mode_id=$1
  printf '%s/policy.md' "$(mr_mode_dir_for "$mode_id")"
}

mr_mode_memory_dir() {
  mode_id=$1
  printf '%s/memory' "$(mr_mode_dir_for "$mode_id")"
}

mr_mode_goal_file() {
  mode_id=$1
  printf '%s/goal_state.md' "$(mr_mode_memory_dir "$mode_id")"
}

mr_mode_long_horizon_file() {
  mode_id=$1
  printf '%s/long_horizon.md' "$(mr_mode_memory_dir "$mode_id")"
}

mr_mode_log_file() {
  mode_id=$1
  printf '%s/mode.log.md' "$(mr_mode_memory_dir "$mode_id")"
}

mr_mode_subscriptions_file() {
  mode_id=$1
  printf '%s/subscriptions.list' "$(mr_mode_memory_dir "$mode_id")"
}

mr_mode_last_telemetry_file() {
  mode_id=$1
  printf '%s/%s.last.log' "$(mr_telemetry_dir)" "$mode_id"
}

mr_skill_meta_file() {
  skill_id=$1
  printf '%s/skill.meta' "$(mr_skill_dir_for "$skill_id")"
}

mr_mode_ledgers_file() {
  mode_id=$1
  printf '%s/governance.log' "$(mr_mode_dir_for "$mode_id")"
}

mr_mode_event_queue_file() {
  mode_id=$1
  printf '%s/%s.events.log' "$(mr_bus_dir)" "$mode_id"
}

mr_directives_dir() {
  printf '%s/directives' "$(mr_bus_dir)"
}

mr_cooperation_log_file() {
  printf '%s/cooperation.log' "$(mr_bus_dir)"
}

mr_mode_directive_inbox_file() {
  mode_id=$1
  printf '%s/%s.inbox.log' "$(mr_directives_dir)" "$mode_id"
}

mr_mode_directive_cursor_file() {
  mode_id=$1
  printf '%s/directive.cursor' "$(mr_mode_dir_for "$mode_id")"
}

mr_env_get() {
  env_file=$1
  key=$2
  fallback=${3:-}
  if [ ! -f "$env_file" ]; then
    printf '%s' "$fallback"
    return 0
  fi
  value=$(sed -n "s/^${key}=//p" "$env_file" | sed -n '1p')
  if [ -z "$(trim "$value")" ]; then
    printf '%s' "$fallback"
  else
    printf '%s' "$value"
  fi
}

mr_env_set() {
  env_file=$1
  key=$2
  value=$(mr_sanitize_inline "$3")
  tmp_file=$(mktemp)
  found=0
  if [ -f "$env_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        "${key}="*)
          printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
          found=1
          ;;
        *)
          printf '%s\n' "$line" >> "$tmp_file"
          ;;
      esac
    done < "$env_file"
  fi
  if [ "$found" -ne 1 ]; then
    printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
  fi
  mv "$tmp_file" "$env_file"
}

mr_csv_normalize() {
  csv_raw=$1
  printf '%s' "$csv_raw" | tr ';' ',' | tr '\n\r' ',' | awk -F',' '
    {
      out_count = 0
      for (i = 1; i <= NF; i++) {
        item = $i
        gsub(/^[[:space:]]+/, "", item)
        gsub(/[[:space:]]+$/, "", item)
        if (item == "") {
          continue
        }
        key = tolower(item)
        if (seen[key] == 1) {
          continue
        }
        seen[key] = 1
        out[++out_count] = item
      }
    }
    END {
      for (i = 1; i <= out_count; i++) {
        if (i > 1) {
          printf ","
        }
        printf "%s", out[i]
      }
    }
  '
}

mr_csv_to_json_array() {
  csv_raw=$1
  csv_norm=$(mr_csv_normalize "$csv_raw")
  printf '['
  first=1
  old_ifs=$IFS
  IFS=','
  for entry in $csv_norm; do
    clean=$(trim "$entry")
    [ -n "$clean" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$clean")"
  done
  IFS=$old_ifs
  printf ']'
}

mr_mode_seed_rows() {
  cat <<'EOF_ROWS'
mastermind-agency-composer|Mastermind / Agency-Composer|9|900|1|Allocates and composes agencies, dashboards, and cross-mode orchestration.|queue,git,run_events,mode_runtime|filesystem,network,agent_spawn|agent-spawner,panel-integrator,dashboard-builder
continuity-of-intention|Continuity-of-Intention|8|600|1|Maintains cross-session teleological alignment and corrects execution drift.|queue,run_events,mode_runtime,assumptions|filesystem|proceduralization,shadow-documentation,report-synthesizer
semantic-watchtower|Semantic Watchtower|7|1200|1|Monitors domains for semantic drift and emergent conceptual bifurcations.|queue,git,run_events,mode_runtime|network|market-research,report-synthesizer,latent-opportunity-harvester
ethical-statutory-compliance|Ethical / Statutory Compliance|10|900|1|Tracks legal and platform constraints and gates risky action chains.|queue,run_events,compliance,mode_runtime|network,filesystem|compliance-lookup,contract-analyzer,report-synthesizer
reputation-thermostat|Reputation Thermostat|6|1500|1|Models signal dilution and tunes costly-signal thresholds dynamically.|queue,run_events,mode_runtime|network|market-research,pitch-drafter,report-synthesizer
failure-mode-simulator|Failure-Mode Simulator|7|1200|1|Evolves collapse scenarios and stress-tests systemic resilience.|queue,git,run_events,mode_runtime|filesystem|simulation-runner,report-synthesizer,devils-liquidity-provider
epistemic-calibration|Epistemic Calibration|6|1800|0|Tracks forecast accuracy and updates strategic priors longitudinally.|run_events,mode_runtime,telemetry|filesystem|report-synthesizer,simulation-runner
adversarial-red-team-twin|Adversarial Red-Team Twin|9|900|1|Attempts to falsify system designs and surfaces exploit strategies.|queue,git,run_events,mode_runtime|filesystem,network|contract-analyzer,simulation-runner,proceduralization
narrative-coherence-engine|Narrative Coherence Engine|5|1800|0|Harmonizes symbolic and terminological consistency across artifacts.|run_events,mode_runtime|filesystem|shadow-documentation,pitch-drafter,report-synthesizer
chrono-budgeter|Chrono-Budgeter|5|900|0|Allocates cognitive labor based on lagged ROI and queue pressure.|queue,run_events,mode_runtime|filesystem|devils-liquidity-provider,proceduralization,report-synthesizer
EOF_ROWS
}

mr_skill_seed_rows() {
  cat <<'EOF_ROWS'
proceduralization|Proceduralization|when manual success patterns repeat|filesystem|Observes repeatable workflows and codifies reusable scripts and runbooks.
grant-hunter|Grant-Hunter|when funding search is requested|network|Tracks funding opportunities and drafts submission-ready packages.
negotiation-doppelganger|Negotiation Doppelganger|when negotiation strategy is requested|filesystem|Simulates counterparties and generates BATNA trees.
devils-liquidity-provider|Devils Liquidity Provider|when execution stalls|filesystem|Injects substitute actions to unblock delivery.
shadow-documentation|Shadow Documentation|when implementation changes frequently|filesystem|Continuously maintains READMEs and architecture diagrams.
latent-opportunity-harvester|Latent Opportunity Harvester|when cross-domain synthesis is valuable|network|Scans for complementarities and latent slack opportunities.
dashboard-builder|Dashboard Builder|when telemetry needs visualization|filesystem|Builds modular synoptic dashboard definitions.
agent-spawner|Agent Spawner|when sub-agents are needed|agent_spawn,filesystem|Instantiates scoped child agents from templates.
panel-integrator|Panel Integrator|when multi-agent telemetry should unify|filesystem|Binds multi-agent telemetry streams into unified panels.
compliance-lookup|Compliance Lookup|when legal or policy checks are needed|network|Retrieves statutory and platform-policy constraints on demand.
report-synthesizer|Report Synthesizer|when structured reporting is needed|filesystem|Produces concise structured summaries from multi-agent outputs.
market-research|Market Research|when demand or competition scans are requested|network|Runs bounded demand and competitor analyses.
contract-analyzer|Contract Analyzer|when agreement risk review is needed|filesystem|Parses agreements for obligations and risk surfaces.
pitch-drafter|Pitch Drafter|when stakeholder narrative is needed|filesystem|Drafts tailored pitches for specific audiences.
data-etl|Data ETL|when data routing or ingestion is needed|filesystem,network|Ingests, normalizes, and routes structured or unstructured data.
web-scraper|Web-Scraper|when external stream extraction is needed|network|Extracts web data under policy constraints.
simulation-runner|Simulation Runner|when scenario analysis is requested|filesystem|Executes bounded scenario and stress simulations.
codegen-infra-spin-up|Codegen / Infra Spin-Up|when infrastructure artifacts are requested|filesystem,network,agent_spawn|Generates infrastructure code and deployment scaffolds.
EOF_ROWS
}

mr_mode_policy_template() {
  mode_name=$1
  mode_desc=$2
  cat <<EOF_POLICY
# $mode_name Policy

## Intent
$mode_desc

## Governance
- This Mode is stateful and acts as a governor.
- It may orchestrate Skills under explicit policy constraints.
- It maintains persistent goal-state and long-horizon memory in its namespace.
- It may emit interrupt requests when interrupt rights are enabled.

## Constraints
- Respect legal, ethical, and platform policy boundaries.
- Prefer reversible actions unless explicit authorization is present.
- Record every scheduler iteration in governance logs.
EOF_POLICY
}

mr_skill_policy_template() {
  skill_name=$1
  skill_desc=$2
  cat <<EOF_POLICY
# $skill_name

## Purpose
$skill_desc

## Skill Contract
- Stateless actuator: no long-term memory persistence.
- No interrupt authority.
- Bounded execution within declared tools and mode policy constraints.
- Inputs and outputs must conform to the declared schema.
EOF_POLICY
}

mr_seed_mode_bundle() {
  mode_id=$1
  mode_name=$2
  mode_priority=$3
  mode_cadence=$4
  mode_interrupt=$5
  mode_desc=$6
  mode_subscriptions=$7
  mode_caps=$8
  mode_skills=$9

  mode_dir=$(mr_mode_dir_for "$mode_id")
  manifest_file=$(mr_mode_manifest_file "$mode_id")
  state_file=$(mr_mode_state_file "$mode_id")
  policy_file=$(mr_mode_policy_file "$mode_id")
  memory_dir=$(mr_mode_memory_dir "$mode_id")

  mkdir -p "$mode_dir"
  mkdir -p "$memory_dir"

  if [ ! -f "$manifest_file" ]; then
    {
      printf 'id=%s\n' "$mode_id"
      printf 'name=%s\n' "$(mr_sanitize_inline "$mode_name")"
      printf 'description=%s\n' "$(mr_sanitize_inline "$mode_desc")"
      printf 'default_priority=%s\n' "$(mr_positive_int_or "$mode_priority" "5")"
      printf 'default_cadence_sec=%s\n' "$(mr_positive_int_or "$mode_cadence" "900")"
      printf 'default_interrupt_rights=%s\n' "$(mr_bool_norm "$mode_interrupt")"
      printf 'default_subscriptions=%s\n' "$(mr_csv_normalize "$mode_subscriptions")"
      printf 'allowed_capabilities=%s\n' "$(mr_csv_normalize "$mode_caps")"
      printf 'recommended_skills=%s\n' "$(mr_csv_normalize "$mode_skills")"
      printf 'memory_namespace=%s\n' "$mode_id"
    } > "$manifest_file"
  fi

  if [ ! -f "$state_file" ]; then
    enabled_default=0
    case "$mode_id" in
      continuity-of-intention|ethical-statutory-compliance)
        enabled_default=1
        ;;
    esac
    {
      printf 'enabled=%s\n' "$enabled_default"
      printf 'priority=%s\n' "$(mr_env_get "$manifest_file" "default_priority" "5")"
      printf 'cadence_sec=%s\n' "$(mr_env_get "$manifest_file" "default_cadence_sec" "900")"
      printf 'interrupt_rights=%s\n' "$(mr_env_get "$manifest_file" "default_interrupt_rights" "0")"
      printf 'allow_queue_injection=0\n'
      printf 'goal_state=\n'
      printf 'status=idle\n'
      printf 'drift_score=0.00\n'
      printf 'last_tick=0\n'
      printf 'next_tick=0\n'
      printf 'last_skill_plan=\n'
      printf 'last_directive_count=0\n'
      printf 'last_directive_emits=0\n'
      printf 'last_directive_summary=none\n'
    } > "$state_file"
  fi

  if [ ! -f "$policy_file" ]; then
    mr_mode_policy_template "$mode_name" "$mode_desc" > "$policy_file"
  fi

  goal_file=$(mr_mode_goal_file "$mode_id")
  if [ ! -f "$goal_file" ]; then
    cat > "$goal_file" <<'EOF_GOAL'
# Goal State

- Pending explicit objective.
EOF_GOAL
  fi

  long_horizon_file=$(mr_mode_long_horizon_file "$mode_id")
  if [ ! -f "$long_horizon_file" ]; then
    cat > "$long_horizon_file" <<'EOF_LONG'
# Long-Horizon Memory

EOF_LONG
  fi

  mode_log_file=$(mr_mode_log_file "$mode_id")
  if [ ! -f "$mode_log_file" ]; then
    cat > "$mode_log_file" <<'EOF_LOG'
# Mode Log

EOF_LOG
  fi

  subscriptions_file=$(mr_mode_subscriptions_file "$mode_id")
  if [ ! -f "$subscriptions_file" ]; then
    printf '%s\n' "$(mr_env_get "$manifest_file" "default_subscriptions" "queue,run_events,mode_runtime")" > "$subscriptions_file"
  fi

  governance_file=$(mr_mode_ledgers_file "$mode_id")
  if [ ! -f "$governance_file" ]; then
    cat > "$governance_file" <<'EOF_GOV'
# Governance Ledger

EOF_GOV
  fi

  mode_events=$(mr_mode_event_queue_file "$mode_id")
  if [ ! -f "$mode_events" ]; then
    : > "$mode_events"
  fi

  mode_inbox_file=$(mr_mode_directive_inbox_file "$mode_id")
  if [ ! -f "$mode_inbox_file" ]; then
    : > "$mode_inbox_file"
  fi
  mode_cursor_file=$(mr_mode_directive_cursor_file "$mode_id")
  if [ ! -f "$mode_cursor_file" ]; then
    printf '0\n' > "$mode_cursor_file"
  fi
}

mr_seed_skill_bundle() {
  skill_id=$1
  skill_name=$2
  trigger_text=$3
  capabilities=$4
  description_text=$5

  skill_dir=$(mr_skill_dir_for "$skill_id")
  mkdir -p "$skill_dir"

  policy_file="$skill_dir/policy.md"
  trigger_file="$skill_dir/trigger.yaml"
  tools_file="$skill_dir/tools.json"
  schema_file="$skill_dir/output.schema.json"
  meta_file=$(mr_skill_meta_file "$skill_id")

  if [ ! -f "$policy_file" ]; then
    mr_skill_policy_template "$skill_name" "$description_text" > "$policy_file"
  fi

  if [ ! -f "$trigger_file" ]; then
    cat > "$trigger_file" <<EOF_TRIGGER
id: $skill_id
name: "$skill_name"
trigger:
  - "$trigger_text"
mode_required: true
stateless: true
interrupt_authority: false
EOF_TRIGGER
  fi

  if [ ! -f "$tools_file" ]; then
    tools_json=$(mr_csv_to_json_array "$capabilities")
    cat > "$tools_file" <<EOF_TOOLS
{
  "tools": $tools_json,
  "requires_mode_authorization": true,
  "stateless": true,
  "interrupt_authority": false,
  "persistent_memory": false
}
EOF_TOOLS
  fi

  if [ ! -f "$schema_file" ]; then
    cat > "$schema_file" <<EOF_SCHEMA
{
  "\$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "$skill_name output",
  "type": "object",
  "required": ["skill_id", "status", "summary", "actions"],
  "properties": {
    "skill_id": { "type": "string", "const": "$skill_id" },
    "status": { "type": "string", "enum": ["ok", "blocked", "needs_auth"] },
    "summary": { "type": "string" },
    "actions": { "type": "array", "items": { "type": "string" } },
    "artifacts": { "type": "array", "items": { "type": "string" } },
    "notes": { "type": "string" }
  },
  "additionalProperties": true
}
EOF_SCHEMA
  fi

  if [ ! -f "$meta_file" ]; then
    {
      printf 'id=%s\n' "$skill_id"
      printf 'name=%s\n' "$(mr_sanitize_inline "$skill_name")"
      printf 'trigger=%s\n' "$(mr_sanitize_inline "$trigger_text")"
      printf 'capabilities=%s\n' "$(mr_csv_normalize "$capabilities")"
      printf 'description=%s\n' "$(mr_sanitize_inline "$description_text")"
      printf 'stateless=1\n'
      printf 'interrupt_authority=0\n'
    } > "$meta_file"
  fi
}

mr_seed_dashboards() {
  dashboard_root=$(mr_dashboard_dir)
  mkdir -p "$dashboard_root"
  composites_file="$dashboard_root/composites.md"
  if [ ! -f "$composites_file" ]; then
    cat > "$composites_file" <<'EOF_COMP'
# Composite Dashboards

- Reputation Monitoring Panel
- Grant / Income Panel
- Oracle / Intel Panel
- Global Dashboard
EOF_COMP
  fi
}

mode_runtime_bootstrap() {
  mkdir -p "$(mr_modes_dir)"
  mkdir -p "$(mr_skills_dir)"
  mkdir -p "$(mr_bus_dir)"
  mkdir -p "$(mr_directives_dir)"
  mkdir -p "$(mr_dashboard_dir)"
  mkdir -p "$(mr_scheduler_dir)"
  mkdir -p "$(mr_telemetry_dir)"
  mkdir -p "$(mr_interrupts_dir)"

  scheduler_state=$(mr_scheduler_state_file)
  if [ ! -f "$scheduler_state" ]; then
    {
      printf 'last_tick=0\n'
      printf 'last_tick_iso=\n'
      printf 'ticks=0\n'
      printf 'last_due_modes=0\n'
      printf 'last_injections=0\n'
      printf 'last_directives_received=0\n'
      printf 'last_directives_emitted=0\n'
      printf 'last_summary=Scheduler initialized\n'
    } > "$scheduler_state"
  fi

  cooperation_log=$(mr_cooperation_log_file)
  if [ ! -f "$cooperation_log" ]; then
    : > "$cooperation_log"
  fi

  mr_mode_seed_rows | while IFS='|' read -r mode_id mode_name mode_priority mode_cadence mode_interrupt mode_desc mode_subscriptions mode_caps mode_skills; do
    [ -n "$mode_id" ] || continue
    mr_seed_mode_bundle "$mode_id" "$mode_name" "$mode_priority" "$mode_cadence" "$mode_interrupt" "$mode_desc" "$mode_subscriptions" "$mode_caps" "$mode_skills"
  done

  mr_skill_seed_rows | while IFS='|' read -r skill_id skill_name trigger_text capabilities description_text; do
    [ -n "$skill_id" ] || continue
    mr_seed_skill_bundle "$skill_id" "$skill_name" "$trigger_text" "$capabilities" "$description_text"
  done

  mr_seed_dashboards
}

mr_mode_exists() {
  mode_id=$1
  mode_dir=$(mr_mode_dir_for "$mode_id")
  [ -d "$mode_dir" ]
}

mr_skill_exists() {
  skill_id=$1
  skill_dir=$(mr_skill_dir_for "$skill_id")
  [ -d "$skill_dir" ]
}

mr_mode_allowed_capabilities() {
  mode_id=$1
  manifest_file=$(mr_mode_manifest_file "$mode_id")
  mr_env_get "$manifest_file" "allowed_capabilities" ""
}

mr_mode_recommended_skills() {
  mode_id=$1
  manifest_file=$(mr_mode_manifest_file "$mode_id")
  mr_env_get "$manifest_file" "recommended_skills" ""
}

mr_mode_subscriptions_current() {
  mode_id=$1
  subs_file=$(mr_mode_subscriptions_file "$mode_id")
  if [ -f "$subs_file" ]; then
    mr_csv_normalize "$(cat "$subs_file" 2>/dev/null || true)"
    return 0
  fi
  manifest_file=$(mr_mode_manifest_file "$mode_id")
  mr_env_get "$manifest_file" "default_subscriptions" "queue,run_events,mode_runtime"
}

mr_list_mode_ids() {
  for mode_dir in "$(mr_modes_dir)"/*; do
    [ -d "$mode_dir" ] || continue
    basename "$mode_dir"
  done | sort
}

mr_list_skill_ids() {
  for skill_dir in "$(mr_skills_dir)"/*; do
    [ -d "$skill_dir" ] || continue
    basename "$skill_dir"
  done | sort
}

mr_queue_metrics() {
  workspaces=0
  conversations=0
  pending=0
  running=0
  done=0
  errors=0

  for ws_dir in "$workspaces_dir"/*; do
    [ -d "$ws_dir" ] || continue
    workspaces=$((workspaces + 1))
    conv_root="$ws_dir/conversations"
    [ -d "$conv_root" ] || continue
    for conv_dir in "$conv_root"/*; do
      [ -d "$conv_dir" ] || continue
      conversations=$((conversations + 1))
      queue_info=$(queue_state_for_conversation "$conv_dir")
      q_pending=$(kv_get "pending" "$queue_info")
      q_running=$(kv_get "running" "$queue_info")
      q_done=$(kv_get "done" "$queue_info")
      q_status=$(kv_get "last_status" "$queue_info")
      case "$q_pending" in ""|*[!0-9]*) q_pending=0 ;; esac
      case "$q_running" in ""|*[!0-9]*) q_running=0 ;; esac
      case "$q_done" in ""|*[!0-9]*) q_done=0 ;; esac
      pending=$((pending + q_pending))
      running=$((running + q_running))
      done=$((done + q_done))
      case "$q_status" in
        error)
          errors=$((errors + 1))
          ;;
      esac
    done
  done

  {
    printf 'workspaces=%s\n' "$workspaces"
    printf 'conversations=%s\n' "$conversations"
    printf 'pending=%s\n' "$pending"
    printf 'running=%s\n' "$running"
    printf 'done=%s\n' "$done"
    printf 'errors=%s\n' "$errors"
  }
}

mr_feed_payload() {
  feed_id=$1
  timestamp=$2

  case "$feed_id" in
    queue)
      metrics=$(mr_queue_metrics)
      pending=$(printf '%s\n' "$metrics" | sed -n 's/^pending=//p' | sed -n '1p')
      running=$(printf '%s\n' "$metrics" | sed -n 's/^running=//p' | sed -n '1p')
      errors=$(printf '%s\n' "$metrics" | sed -n 's/^errors=//p' | sed -n '1p')
      printf '[%s] queue pending=%s running=%s errors=%s' "$timestamp" "${pending:-0}" "${running:-0}" "${errors:-0}"
      ;;
    git)
      dirty_count=0
      for ws_dir in "$workspaces_dir"/*; do
        [ -d "$ws_dir" ] || continue
        ws_path=$(read_file_line "$ws_dir/path" "")
        if [ -n "$ws_path" ] && [ -d "$ws_path/.git" ]; then
          status_out=$( (cd "$ws_path" && git status --short 2>/dev/null) || true )
          if [ -n "$(trim "$status_out")" ]; then
            dirty_count=$((dirty_count + 1))
          fi
        fi
      done
      printf '[%s] git dirty_workspaces=%s' "$timestamp" "$dirty_count"
      ;;
    run_events)
      run_event_count=0
      for ws_dir in "$workspaces_dir"/*; do
        [ -d "$ws_dir" ] || continue
        conv_root="$ws_dir/conversations"
        [ -d "$conv_root" ] || continue
        for conv_dir in "$conv_root"/*; do
          [ -d "$conv_dir" ] || continue
          run_events_file="$conv_dir/run_events.ndjson"
          if [ -f "$run_events_file" ]; then
            count=$(wc -l < "$run_events_file" 2>/dev/null | tr -d '[:space:]' || printf '0')
            case "$count" in ""|*[!0-9]*) count=0 ;; esac
            run_event_count=$((run_event_count + count))
          fi
        done
      done
      printf '[%s] run_events total=%s' "$timestamp" "$run_event_count"
      ;;
    mode_runtime)
      ticks=$(mr_env_get "$(mr_scheduler_state_file)" "ticks" "0")
      summary=$(mr_env_get "$(mr_scheduler_state_file)" "last_summary" "none")
      printf '[%s] scheduler ticks=%s summary=%s' "$timestamp" "$ticks" "$summary"
      ;;
    assumptions)
      printf '[%s] assumptions feed: active' "$timestamp"
      ;;
    telemetry)
      printf '[%s] telemetry feed: active' "$timestamp"
      ;;
    compliance)
      printf '[%s] compliance feed: active' "$timestamp"
      ;;
    *)
      printf '[%s] %s feed: no adapter' "$timestamp" "$feed_id"
      ;;
  esac
}

mr_log_mode_iteration() {
  mode_id=$1
  status_text=$2
  drift_score=$3
  skills_text=$4
  telemetry_text=$5
  injected_item=$6
  directives_received=${7:-0}
  directives_emitted=${8:-0}
  directive_summary=${9:-none}

  timestamp=$(mr_now_iso)
  mode_log_file=$(mr_mode_log_file "$mode_id")
  long_file=$(mr_mode_long_horizon_file "$mode_id")
  governance_file=$(mr_mode_ledgers_file "$mode_id")

  {
    printf '## %s\n' "$timestamp"
    printf 'Status: %s\n' "$status_text"
    printf 'Drift score: %s\n' "$drift_score"
    printf 'Skill plan: %s\n' "$skills_text"
    printf 'Telemetry: %s\n' "$telemetry_text"
    printf 'Directives received: %s\n' "$directives_received"
    printf 'Directives emitted: %s\n' "$directives_emitted"
    printf 'Directive summary: %s\n' "$directive_summary"
    if [ -n "$(trim "$injected_item")" ]; then
      printf 'Queue injection: %s\n' "$injected_item"
    fi
    printf '\n'
  } >> "$mode_log_file"

  {
    printf -- '- %s status=%s drift=%s skills=%s directives_in=%s directives_out=%s\n' \
      "$timestamp" "$status_text" "$drift_score" "$skills_text" "$directives_received" "$directives_emitted"
  } >> "$long_file"

  {
    printf '%s\tmode=%s\tstatus=%s\tdrift=%s\tskills=%s\tdirectives_in=%s\tdirectives_out=%s\tinjected=%s\n' \
      "$timestamp" "$mode_id" "$status_text" "$drift_score" "$skills_text" "$directives_received" "$directives_emitted" "${injected_item:-none}"
  } >> "$governance_file"
}

mr_queue_signals_triplet() {
  if [ -n "${MR_QUEUE_SIGNALS_OVERRIDE:-}" ]; then
    printf '%s' "$MR_QUEUE_SIGNALS_OVERRIDE"
    return 0
  fi
  metrics=$(mr_queue_metrics)
  pending=$(printf '%s\n' "$metrics" | sed -n 's/^pending=//p' | sed -n '1p')
  running=$(printf '%s\n' "$metrics" | sed -n 's/^running=//p' | sed -n '1p')
  errors=$(printf '%s\n' "$metrics" | sed -n 's/^errors=//p' | sed -n '1p')
  case "$pending" in ""|*[!0-9]*) pending=0 ;; esac
  case "$running" in ""|*[!0-9]*) running=0 ;; esac
  case "$errors" in ""|*[!0-9]*) errors=0 ;; esac
  printf '%s|%s|%s' "$pending" "$running" "$errors"
}

mr_csv_first_n() {
  csv_raw=$1
  max_items=$2
  case "$max_items" in ""|*[!0-9]*) max_items=4 ;; esac
  if [ "$max_items" -le 0 ]; then
    printf '%s' ""
    return 0
  fi
  norm=$(mr_csv_normalize "$csv_raw")
  out=""
  count=0
  old_ifs=$IFS
  IFS=','
  for entry in $norm; do
    clean=$(trim "$entry")
    [ -n "$clean" ] || continue
    count=$((count + 1))
    if [ "$count" -gt "$max_items" ]; then
      break
    fi
    if [ -n "$out" ]; then
      out="$out,$clean"
    else
      out="$clean"
    fi
  done
  IFS=$old_ifs
  printf '%s' "$out"
}

mr_directive_payload_clean() {
  payload_raw=$1
  payload_clean=$(mr_sanitize_inline "$payload_raw" | tr '\t' ' ' | tr '|' '/' | sed 's/[[:space:]]\+/ /g')
  payload_clean=$(trim "$payload_clean")
  if [ -z "$payload_clean" ]; then
    payload_clean="no-payload"
  fi
  printf '%s' "$payload_clean" | awk 'BEGIN { ORS="" } { print substr($0, 1, 240) }'
}

mr_mode_recent_directive_exists() {
  from_mode=$1
  to_mode=$2
  directive_kind=$3
  directive_payload=$4
  max_age_sec=$5

  case "$max_age_sec" in
    ""|*[!0-9]*) max_age_sec=300 ;;
  esac

  coop_log=$(mr_cooperation_log_file)
  [ -f "$coop_log" ] || return 1

  now_epoch=$(mr_now_epoch)
  case "$now_epoch" in ""|*[!0-9]*) now_epoch=0 ;; esac

  tail -n 240 "$coop_log" 2>/dev/null | awk -F'\t' \
    -v now="$now_epoch" \
    -v max_age="$max_age_sec" \
    -v from="$from_mode" \
    -v to="$to_mode" \
    -v kind="$directive_kind" \
    -v payload="$directive_payload" '
      {
        epoch = $1 + 0
        if ($3 != from || $4 != to || $5 != kind || $7 != payload) {
          next
        }
        if (now <= 0) {
          print "1"
          exit 0
        }
        if (now - epoch <= max_age) {
          print "1"
          exit 0
        }
      }
    ' | grep -q '^1$'
}

mr_mode_emit_directive() {
  from_mode=$1
  to_mode=$2
  directive_kind=$3
  directive_priority=$4
  directive_payload_raw=$5
  ttl_sec=$6

  if ! valid_id "$from_mode" || ! valid_id "$to_mode"; then
    printf '%s' ""
    return 0
  fi
  if [ "$from_mode" = "$to_mode" ]; then
    printf '%s' ""
    return 0
  fi
  if ! mr_mode_exists "$from_mode" || ! mr_mode_exists "$to_mode"; then
    printf '%s' ""
    return 0
  fi

  directive_kind=$(printf '%s' "$directive_kind" | tr '[:upper:]' '[:lower:]')
  if [ -z "$(trim "$directive_kind")" ]; then
    directive_kind="coordination-note"
  fi

  case "$directive_priority" in
    ""|*[!0-9]*) directive_priority=5 ;;
  esac
  if [ "$directive_priority" -lt 1 ]; then
    directive_priority=1
  fi
  if [ "$directive_priority" -gt 10 ]; then
    directive_priority=10
  fi

  case "$ttl_sec" in
    ""|*[!0-9]*) ttl_sec=3600 ;;
  esac
  if [ "$ttl_sec" -lt 60 ]; then
    ttl_sec=60
  fi
  if [ "$ttl_sec" -gt 86400 ]; then
    ttl_sec=86400
  fi

  directive_payload=$(mr_directive_payload_clean "$directive_payload_raw")
  if mr_mode_recent_directive_exists "$from_mode" "$to_mode" "$directive_kind" "$directive_payload" "300"; then
    printf '%s' ""
    return 0
  fi

  now_epoch=$(mr_now_epoch)
  case "$now_epoch" in ""|*[!0-9]*) now_epoch=0 ;; esac
  now_iso=$(mr_now_iso)
  expires_epoch=$((now_epoch + ttl_sec))

  target_inbox=$(mr_mode_directive_inbox_file "$to_mode")
  coop_log=$(mr_cooperation_log_file)
  mkdir -p "$(mr_directives_dir)"
  [ -f "$target_inbox" ] || : > "$target_inbox"
  [ -f "$coop_log" ] || : > "$coop_log"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$now_epoch" "$now_iso" "$from_mode" "$directive_kind" "$directive_priority" "$directive_payload" "$expires_epoch" >> "$target_inbox"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$now_epoch" "$now_iso" "$from_mode" "$to_mode" "$directive_kind" "$directive_priority" "$directive_payload" "$expires_epoch" >> "$coop_log"

  printf '%s' "${now_epoch}:${from_mode}->${to_mode}:${directive_kind}"
}

mr_mode_directive_hints_from_kind() {
  directive_kind=$1
  case "$directive_kind" in
    compliance-gate|risk-surface)
      printf '%s' "compliance-lookup,contract-analyzer,report-synthesizer"
      ;;
    throughput-rebalance|throttle-guidance)
      printf '%s' "devils-liquidity-provider,data-etl,proceduralization"
      ;;
    narrative-alignment|brand-coherence)
      printf '%s' "shadow-documentation,pitch-drafter,report-synthesizer"
      ;;
    resilience-probe|adversarial-probe)
      printf '%s' "simulation-runner,contract-analyzer,report-synthesizer"
      ;;
    intel-refresh|opportunity-scan)
      printf '%s' "market-research,latent-opportunity-harvester,report-synthesizer"
      ;;
    priority-escalation|trajectory-update)
      printf '%s' "report-synthesizer,proceduralization"
      ;;
    *)
      printf '%s' "report-synthesizer"
      ;;
  esac
}

mr_mode_consume_directives() {
  mode_id=$1
  max_items=$2
  case "$max_items" in
    ""|*[!0-9]*) max_items=8 ;;
  esac
  if [ "$max_items" -lt 1 ]; then
    max_items=1
  fi

  inbox_file=$(mr_mode_directive_inbox_file "$mode_id")
  cursor_file=$(mr_mode_directive_cursor_file "$mode_id")
  [ -f "$inbox_file" ] || {
    printf '%s' "0|none||0"
    return 0
  }
  [ -f "$cursor_file" ] || printf '0\n' > "$cursor_file"

  total_lines=$(wc -l < "$inbox_file" 2>/dev/null | tr -d '[:space:]' || printf '0')
  case "$total_lines" in ""|*[!0-9]*) total_lines=0 ;; esac
  cursor_line=$(read_file_line "$cursor_file" "0")
  case "$cursor_line" in ""|*[!0-9]*) cursor_line=0 ;; esac

  if [ "$total_lines" -le "$cursor_line" ]; then
    printf '%s' "0|none||0"
    return 0
  fi

  start_line=$((cursor_line + 1))
  delta_file=$(mktemp)
  sed -n "${start_line},${total_lines}p" "$inbox_file" > "$delta_file"
  printf '%s\n' "$total_lines" > "$cursor_file"

  now_epoch=$(mr_now_epoch)
  case "$now_epoch" in ""|*[!0-9]*) now_epoch=0 ;; esac
  mode_events_file=$(mr_mode_event_queue_file "$mode_id")
  [ -f "$mode_events_file" ] || : > "$mode_events_file"

  directive_count=0
  summary=""
  skill_hints=""
  priority_boost=0
  summary_count=0

  while IFS="$(printf '\t')" read -r directive_epoch directive_iso from_mode directive_kind directive_priority directive_payload expires_epoch || [ -n "$directive_epoch$directive_kind$directive_payload" ]; do
    [ -n "$(trim "$directive_kind")" ] || continue
    case "$expires_epoch" in ""|*[!0-9]*) expires_epoch=0 ;; esac
    if [ "$expires_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ] && [ "$expires_epoch" -lt "$now_epoch" ]; then
      continue
    fi

    directive_count=$((directive_count + 1))
    if [ "$summary_count" -lt "$max_items" ]; then
      snippet=$(mr_directive_payload_clean "$directive_payload")
      summary_piece="${from_mode}:${directive_kind}(${snippet})"
      if [ -n "$summary" ]; then
        summary="$summary; $summary_piece"
      else
        summary="$summary_piece"
      fi
      summary_count=$((summary_count + 1))
    fi

    kind_hints=$(mr_mode_directive_hints_from_kind "$directive_kind")
    skill_hints=$(mr_csv_normalize "$skill_hints,$kind_hints")

    case "$directive_kind" in
      priority-escalation|compliance-gate|interrupt-request)
        if [ "$priority_boost" -lt 3 ]; then
          priority_boost=$((priority_boost + 1))
        fi
        ;;
    esac

    printf '%s\tevent=directive_received\tfrom=%s\tkind=%s\tpriority=%s\tpayload=%s\n' \
      "$(mr_now_iso)" "$from_mode" "$directive_kind" "$directive_priority" "$(mr_directive_payload_clean "$directive_payload")" >> "$mode_events_file"
  done < "$delta_file"
  rm -f "$delta_file"

  if [ -z "$(trim "$summary")" ]; then
    summary="none"
  fi

  printf '%s|%s|%s|%s' "$directive_count" "$summary" "$skill_hints" "$priority_boost"
}

mr_mode_cooperation_plan_lines() {
  mode_id=$1
  status_text=$2
  drift_score=$3
  q_pending=$4
  q_running=$5
  q_errors=$6
  directives_in=$7

  drift_bucket=0
  if awk -v v="$drift_score" 'BEGIN { exit (v >= 0.70 ? 0 : 1) }'; then
    drift_bucket=2
  elif awk -v v="$drift_score" 'BEGIN { exit (v >= 0.45 ? 0 : 1) }'; then
    drift_bucket=1
  fi

  if [ "$q_errors" -gt 0 ]; then
    printf '%s\n' "ethical-statutory-compliance|compliance-gate|9|Queue errors detected; run compliance gating and mitigation checks.|5400"
  fi
  if [ "$q_pending" -gt 10 ]; then
    printf '%s\n' "chrono-budgeter|throughput-rebalance|8|Queue backlog is elevated; rebalance cadence and propose throughput recovery actions.|3600"
  fi
  if [ "$drift_bucket" -ge 2 ]; then
    printf '%s\n' "continuity-of-intention|priority-escalation|9|High drift detected; enforce continuity guardrails and stabilize execution trajectory.|3600"
  fi

  case "$mode_id" in
    mastermind-agency-composer)
      if [ "$q_pending" -eq 0 ] && [ "$q_running" -eq 0 ]; then
        printf '%s\n' "semantic-watchtower|intel-refresh|6|Queue is idle; refresh opportunity and semantic-intel scan for next strategic moves.|5400"
      fi
      ;;
    semantic-watchtower)
      if [ "$q_pending" -le 2 ] && [ "$q_errors" -eq 0 ]; then
        printf '%s\n' "mastermind-agency-composer|opportunity-scan|5|Semantic monitoring is stable; synthesize candidate opportunities for orchestration.|7200"
      fi
      ;;
    failure-mode-simulator)
      if [ "$q_errors" -gt 0 ] || [ "$drift_bucket" -ge 1 ]; then
        printf '%s\n' "adversarial-red-team-twin|resilience-probe|8|Failure pressure observed; run adversarial stress probes against current strategy.|3600"
      fi
      ;;
    adversarial-red-team-twin)
      if [ "$q_errors" -gt 0 ]; then
        printf '%s\n' "ethical-statutory-compliance|risk-surface|8|Adversarial pressure surfaced elevated risk; run policy/legal risk-surface review.|3600"
      fi
      ;;
    narrative-coherence-engine)
      if [ "$status_text" = "alignment-repair" ]; then
        printf '%s\n' "continuity-of-intention|narrative-alignment|7|Narrative alignment degraded; harmonize terminology with active objectives.|3600"
      fi
      ;;
    reputation-thermostat)
      if [ "$q_errors" -gt 0 ] || [ "$drift_bucket" -ge 1 ]; then
        printf '%s\n' "narrative-coherence-engine|brand-coherence|6|Reputation pressure elevated; reinforce coherent narrative and terminology controls.|5400"
      fi
      ;;
    chrono-budgeter)
      if [ "$status_text" = "throttle-recommend" ] || [ "$q_pending" -gt 12 ]; then
        printf '%s\n' "continuity-of-intention|throttle-guidance|7|Chrono budget indicates overload; tighten scope and rebalance objective sequencing.|3600"
      fi
      ;;
    continuity-of-intention)
      if [ "$directives_in" -gt 0 ]; then
        printf '%s\n' "mastermind-agency-composer|trajectory-update|6|Integrated cross-mode directives; update global execution trajectory accordingly.|5400"
      fi
      ;;
  esac
}

mr_mode_focus_text() {
  mode_id=$1
  case "$mode_id" in
    mastermind-agency-composer)
      printf '%s' "agency composition and multi-panel orchestration"
      ;;
    continuity-of-intention)
      printf '%s' "cross-session objective continuity and drift correction"
      ;;
    semantic-watchtower)
      printf '%s' "semantic drift detection and conceptual bifurcation tracking"
      ;;
    ethical-statutory-compliance)
      printf '%s' "legal/platform compliance gating and constraint enforcement"
      ;;
    reputation-thermostat)
      printf '%s' "reputation signal-cost control and trust preservation"
      ;;
    failure-mode-simulator)
      printf '%s' "collapse scenario simulation and resilience stress-testing"
      ;;
    epistemic-calibration)
      printf '%s' "forecast calibration and longitudinal prior updates"
      ;;
    adversarial-red-team-twin)
      printf '%s' "adversarial falsification and exploit surface probing"
      ;;
    narrative-coherence-engine)
      printf '%s' "terminology consistency and narrative coherence"
      ;;
    chrono-budgeter)
      printf '%s' "effort allocation and queue-time ROI optimization"
      ;;
    *)
      printf '%s' "bounded multi-step execution"
      ;;
  esac
}

mr_policy_skill_plan() {
  mode_id=$1
  base=$(mr_mode_recommended_skills "$mode_id")
  [ -n "$(trim "$base")" ] || base="report-synthesizer"

  signals=$(mr_queue_signals_triplet)
  q_pending=$(printf '%s' "$signals" | cut -d'|' -f1)
  q_running=$(printf '%s' "$signals" | cut -d'|' -f2)
  q_errors=$(printf '%s' "$signals" | cut -d'|' -f3)

  dynamic=""
  case "$mode_id" in
    ethical-statutory-compliance)
      dynamic="compliance-lookup,contract-analyzer,report-synthesizer"
      ;;
    semantic-watchtower)
      dynamic="market-research,latent-opportunity-harvester,report-synthesizer"
      ;;
    continuity-of-intention)
      dynamic="proceduralization,shadow-documentation,report-synthesizer"
      ;;
    mastermind-agency-composer)
      dynamic="agent-spawner,panel-integrator,dashboard-builder"
      if [ "$q_pending" -eq 0 ] && [ "$q_running" -eq 0 ]; then
        dynamic="$dynamic,latent-opportunity-harvester"
      fi
      ;;
    failure-mode-simulator)
      dynamic="simulation-runner,contract-analyzer,report-synthesizer"
      ;;
    narrative-coherence-engine)
      dynamic="shadow-documentation,pitch-drafter,report-synthesizer"
      ;;
    adversarial-red-team-twin)
      dynamic="contract-analyzer,simulation-runner,proceduralization"
      ;;
    reputation-thermostat)
      dynamic="market-research,pitch-drafter,report-synthesizer"
      ;;
    chrono-budgeter)
      dynamic="devils-liquidity-provider,proceduralization,data-etl"
      ;;
    epistemic-calibration)
      dynamic="report-synthesizer,simulation-runner,market-research"
      ;;
  esac

  if [ "$q_errors" -gt 0 ]; then
    dynamic="$dynamic,devils-liquidity-provider,compliance-lookup"
  fi
  if [ "$q_pending" -gt 8 ]; then
    dynamic="$dynamic,data-etl,devils-liquidity-provider"
  fi
  if [ "$q_running" -gt 4 ]; then
    dynamic="$dynamic,report-synthesizer"
  fi

  merged=$(mr_csv_normalize "$base,$dynamic")
  limited=$(mr_csv_first_n "$merged" "5")
  [ -n "$(trim "$limited")" ] || limited="report-synthesizer"
  printf '%s' "$limited"
}

mr_capability_in_list() {
  cap_list=$1
  capability=$2
  norm_list=",$(mr_csv_normalize "$cap_list"),"
  norm_cap=$(trim "$capability")
  [ -n "$norm_cap" ] || return 1
  case "$norm_list" in
    *",$norm_cap,"*) return 0 ;;
  esac
  return 1
}

mr_mode_authorizes_capabilities() {
  mode_id=$1
  requested_caps=$2
  allowed_caps=$(mr_mode_allowed_capabilities "$mode_id")
  req_norm=$(mr_csv_normalize "$requested_caps")
  old_ifs=$IFS
  IFS=','
  for cap in $req_norm; do
    clean=$(trim "$cap")
    [ -n "$clean" ] || continue
    case "$clean" in
      filesystem|network|agent_spawn)
        if ! mr_capability_in_list "$allowed_caps" "$clean"; then
          IFS=$old_ifs
          return 1
        fi
        ;;
    esac
  done
  IFS=$old_ifs
  return 0
}

mr_find_default_target() {
  selected_ws=""
  selected_conv=""
  for ws_dir in "$workspaces_dir"/*; do
    [ -d "$ws_dir" ] || continue
    ws_id=$(basename "$ws_dir")
    conv_root="$ws_dir/conversations"
    [ -d "$conv_root" ] || continue
    for conv_dir in "$conv_root"/*; do
      [ -d "$conv_dir" ] || continue
      selected_ws=$ws_id
      selected_conv=$(basename "$conv_dir")
      printf '%s|%s' "$selected_ws" "$selected_conv"
      return 0
    done
  done
  printf '%s|%s' "$selected_ws" "$selected_conv"
}

mr_try_queue_injection() {
  mode_id=$1
  ws_id=$2
  conv_id=$3
  injection_prompt=$4

  [ -n "$(trim "$injection_prompt")" ] || {
    printf '%s' ""
    return 0
  }

  if [ -z "$ws_id" ] || [ -z "$conv_id" ]; then
    pair=$(mr_find_default_target)
    ws_id=$(printf '%s' "$pair" | cut -d'|' -f1)
    conv_id=$(printf '%s' "$pair" | cut -d'|' -f2)
  fi

  if [ -z "$ws_id" ] || [ -z "$conv_id" ]; then
    printf '%s' ""
    return 0
  fi

  if ! valid_id "$ws_id" || ! valid_id "$conv_id"; then
    printf '%s' ""
    return 0
  fi

  conv_dir=$(conversation_dir_for "$ws_id" "$conv_id")
  if [ ! -d "$conv_dir" ]; then
    printf '%s' ""
    return 0
  fi

  ensure_queue_layout "$conv_dir"
  item_id=$(new_id)
  order=$(queue_allocate_order "$conv_dir" "tail")
  queue_item_file=$(queue_item_file_for "$conv_dir" "$order" "$item_id")
  queue_item_meta=$(queue_item_meta_for_path "$queue_item_file")

  printf '%s\n\n[mode:%s]' "$injection_prompt" "$mode_id" > "$queue_item_file"
  empty_attachment_ids=$(mktemp)
  empty_skill_ids=$(mktemp)
  : > "$empty_attachment_ids"
  : > "$empty_skill_ids"
  queue_meta_write "$queue_item_meta" "assistant" "$mode_id" "auto" "$empty_skill_ids" "$empty_attachment_ids"
  rm -f "$empty_attachment_ids" "$empty_skill_ids"

  printf '%s' "$item_id"
}

mr_mode_tick_one() {
  mode_id=$1
  workspace_id=$2
  conversation_id=$3

  state_file=$(mr_mode_state_file "$mode_id")
  manifest_file=$(mr_mode_manifest_file "$mode_id")

  cadence=$(mr_positive_int_or "$(mr_env_get "$state_file" "cadence_sec" "$(mr_env_get "$manifest_file" "default_cadence_sec" "900")")" "900")
  interrupt_rights=$(mr_bool_norm "$(mr_env_get "$state_file" "interrupt_rights" "$(mr_env_get "$manifest_file" "default_interrupt_rights" "0")")")
  allow_queue_injection=$(mr_bool_norm "$(mr_env_get "$state_file" "allow_queue_injection" "0")")
  directives_feedback=$(mr_mode_consume_directives "$mode_id" "8")
  directives_received=$(printf '%s' "$directives_feedback" | cut -d'|' -f1)
  directives_summary=$(printf '%s' "$directives_feedback" | cut -d'|' -f2)
  directives_skill_hints=$(printf '%s' "$directives_feedback" | cut -d'|' -f3)
  directives_priority_boost=$(printf '%s' "$directives_feedback" | cut -d'|' -f4)
  case "$directives_received" in ""|*[!0-9]*) directives_received=0 ;; esac
  case "$directives_priority_boost" in ""|*[!0-9]*) directives_priority_boost=0 ;; esac
  if [ "$directives_priority_boost" -lt 0 ]; then
    directives_priority_boost=0
  fi

  queue_signals=$(mr_queue_signals_triplet)
  q_pending=$(printf '%s' "$queue_signals" | cut -d'|' -f1)
  q_running=$(printf '%s' "$queue_signals" | cut -d'|' -f2)
  q_errors=$(printf '%s' "$queue_signals" | cut -d'|' -f3)

  case "$q_pending" in ""|*[!0-9]*) q_pending=0 ;; esac
  case "$q_running" in ""|*[!0-9]*) q_running=0 ;; esac
  case "$q_errors" in ""|*[!0-9]*) q_errors=0 ;; esac

  drift_tenths=$((q_errors * 4 + q_pending + q_running * 2))
  if [ "$drift_tenths" -gt 10 ]; then
    drift_tenths=10
  fi
  drift_score=$(awk -v d="$drift_tenths" 'BEGIN { printf "%.2f", d / 10.0 }')

  status_text="healthy"
  if [ "$q_errors" -gt 0 ]; then
    status_text="degraded"
  elif [ "$q_pending" -gt 6 ]; then
    status_text="saturated"
  fi
  case "$mode_id" in
    ethical-statutory-compliance)
      if [ "$q_errors" -gt 0 ]; then
        status_text="intervention-required"
      elif [ "$q_pending" -gt 6 ]; then
        status_text="preemptive-review"
      fi
      ;;
    chrono-budgeter)
      if [ "$q_pending" -gt 12 ]; then
        status_text="throttle-recommend"
      elif [ "$q_pending" -gt 6 ]; then
        status_text="rebalance"
      fi
      ;;
    mastermind-agency-composer)
      if [ "$q_pending" -eq 0 ] && [ "$q_running" -eq 0 ]; then
        status_text="opportunity-scan"
      fi
      ;;
    narrative-coherence-engine)
      if [ "$q_errors" -gt 0 ]; then
        status_text="alignment-repair"
      fi
      ;;
  esac

  if [ "$directives_received" -gt 0 ] && [ "$status_text" = "healthy" ]; then
    status_text="coordinating"
  fi
  if [ "$directives_priority_boost" -ge 2 ] && [ "$q_errors" -eq 0 ] && [ "$q_pending" -le 2 ]; then
    status_text="priority-sync"
  fi

  subscriptions=$(mr_mode_subscriptions_current "$mode_id")
  telemetry_summary=""
  first_feed=1
  old_ifs=$IFS
  IFS=','
  for feed in $subscriptions; do
    feed_clean=$(trim "$feed")
    [ -n "$feed_clean" ] || continue
    feed_payload=$(mr_feed_payload "$feed_clean" "$(mr_now_iso)")
    if [ "$first_feed" -eq 0 ]; then
      telemetry_summary="$telemetry_summary | "
    fi
    first_feed=0
    telemetry_summary="$telemetry_summary$feed_payload"
  done
  IFS=$old_ifs

  if [ -z "$(trim "$telemetry_summary")" ]; then
    telemetry_summary="no telemetry"
  fi

  skill_plan=$(mr_policy_skill_plan "$mode_id")
  if [ -n "$(trim "$directives_skill_hints")" ]; then
    skill_plan=$(mr_csv_normalize "$skill_plan,$directives_skill_hints")
  fi
  skill_plan=$(mr_csv_first_n "$skill_plan" "5")
  [ -n "$(trim "$skill_plan")" ] || skill_plan="report-synthesizer"
  mode_events_file=$(mr_mode_event_queue_file "$mode_id")
  old_ifs=$IFS
  IFS=','
  for suggested_skill in $skill_plan; do
    suggested_skill=$(trim "$suggested_skill")
    [ -n "$suggested_skill" ] || continue
    printf '%s\tevent=skill_suggested\tskill=%s\n' "$(mr_now_iso)" "$suggested_skill" >> "$mode_events_file"
  done
  IFS=$old_ifs

  directives_emitted=0
  cooperation_lines=$(mr_mode_cooperation_plan_lines "$mode_id" "$status_text" "$drift_score" "$q_pending" "$q_running" "$q_errors" "$directives_received")
  if [ -n "$(trim "$cooperation_lines")" ]; then
    emit_guard=0
    while IFS='|' read -r target_mode directive_kind directive_priority directive_payload directive_ttl; do
      [ -n "$(trim "$target_mode")" ] || continue
      emit_guard=$((emit_guard + 1))
      if [ "$emit_guard" -gt 3 ]; then
        break
      fi
      emitted_id=$(mr_mode_emit_directive "$mode_id" "$target_mode" "$directive_kind" "$directive_priority" "$directive_payload" "$directive_ttl")
      if [ -n "$(trim "$emitted_id")" ]; then
        directives_emitted=$((directives_emitted + 1))
        printf '%s\tevent=directive_emitted\tto=%s\tkind=%s\tpriority=%s\tpayload=%s\n' \
          "$(mr_now_iso)" "$target_mode" "$directive_kind" "$directive_priority" "$(mr_directive_payload_clean "$directive_payload")" >> "$mode_events_file"
      fi
    done <<EOF_DIRECTIVES
$cooperation_lines
EOF_DIRECTIVES
  fi

  injection_item=""
  if [ "$allow_queue_injection" = "1" ]; then
    if mr_mode_authorizes_capabilities "$mode_id" "agent_spawn"; then
      injection_item=$(mr_try_queue_injection "$mode_id" "$workspace_id" "$conversation_id" "[Autonomous injection] $mode_id suggests a next-step execution cycle based on current telemetry.")
    fi
  fi

  now_epoch=$(mr_now_epoch)
  next_tick=$((now_epoch + cadence))
  mr_env_set "$state_file" "last_tick" "$now_epoch"
  mr_env_set "$state_file" "next_tick" "$next_tick"
  mr_env_set "$state_file" "status" "$status_text"
  mr_env_set "$state_file" "drift_score" "$drift_score"
  mr_env_set "$state_file" "last_skill_plan" "$skill_plan"
  mr_env_set "$state_file" "last_directive_count" "$directives_received"
  mr_env_set "$state_file" "last_directive_emits" "$directives_emitted"
  mr_env_set "$state_file" "last_directive_summary" "$(mr_directive_payload_clean "$directives_summary")"

  mode_telemetry_file=$(mr_mode_last_telemetry_file "$mode_id")
  {
    printf '%s\n' "$telemetry_summary"
  } >> "$mode_telemetry_file"

  mr_log_mode_iteration "$mode_id" "$status_text" "$drift_score" "$skill_plan" "$telemetry_summary" "$injection_item" "$directives_received" "$directives_emitted" "$directives_summary"

  if [ "$interrupt_rights" = "1" ] && awk -v v="$drift_score" 'BEGIN { exit (v >= 0.70 ? 0 : 1) }'; then
    interrupt_file="$(mr_interrupts_dir)/$(mr_now_epoch)-${mode_id}.json"
    cat > "$interrupt_file" <<EOF_INTERRUPT
{"mode_id":"$(json_escape "$mode_id")","timestamp":"$(json_escape "$(mr_now_iso)")","reason":"drift threshold exceeded","drift_score":"$(json_escape "$drift_score")"}
EOF_INTERRUPT
  fi

  printf '%s|%s|%s|%s|%s|%s|%s|%s' \
    "$mode_id" "$status_text" "$drift_score" "$skill_plan" "$injection_item" "$directives_received" "$directives_emitted" "$(mr_directive_payload_clean "$directives_summary")"
}

mr_mode_scheduler_tick_json() {
  workspace_id=$1
  conversation_id=$2

  now_epoch=$(mr_now_epoch)
  now_iso=$(mr_now_iso)
  tick_queue_signals=$(mr_queue_signals_triplet)
  MR_QUEUE_SIGNALS_OVERRIDE=$tick_queue_signals
  export MR_QUEUE_SIGNALS_OVERRIDE
  active_modes=0
  due_modes=0
  injections=0
  directives_received_total=0
  directives_emitted_total=0

  processed_json=''
  processed_first=1
  due_mode_order_file=$(mktemp)
  : > "$due_mode_order_file"

  for mode_id in $(mr_list_mode_ids); do
    state_file=$(mr_mode_state_file "$mode_id")
    manifest_file=$(mr_mode_manifest_file "$mode_id")
    enabled=$(mr_bool_norm "$(mr_env_get "$state_file" "enabled" "0")")
    [ "$enabled" = "1" ] || continue
    active_modes=$((active_modes + 1))

    next_tick=$(mr_env_get "$state_file" "next_tick" "0")
    case "$next_tick" in ""|*[!0-9]*) next_tick=0 ;; esac
    if [ "$next_tick" -gt "$now_epoch" ]; then
      continue
    fi
    mode_priority=$(mr_positive_int_or "$(mr_env_get "$state_file" "priority" "$(mr_env_get "$manifest_file" "default_priority" "5")")" "5")
    printf '%s|%s\n' "$mode_priority" "$mode_id" >> "$due_mode_order_file"
  done

  while IFS='|' read -r _prio mode_id; do
    [ -n "$mode_id" ] || continue
    due_modes=$((due_modes + 1))
    tick_result=$(mr_mode_tick_one "$mode_id" "$workspace_id" "$conversation_id")
    result_mode=$(printf '%s' "$tick_result" | cut -d'|' -f1)
    result_status=$(printf '%s' "$tick_result" | cut -d'|' -f2)
    result_drift=$(printf '%s' "$tick_result" | cut -d'|' -f3)
    result_skills=$(printf '%s' "$tick_result" | cut -d'|' -f4)
    result_injection=$(printf '%s' "$tick_result" | cut -d'|' -f5)
    result_directives_received=$(printf '%s' "$tick_result" | cut -d'|' -f6)
    result_directives_emitted=$(printf '%s' "$tick_result" | cut -d'|' -f7)
    result_directive_summary=$(printf '%s' "$tick_result" | cut -d'|' -f8-)

    case "$result_directives_received" in ""|*[!0-9]*) result_directives_received=0 ;; esac
    case "$result_directives_emitted" in ""|*[!0-9]*) result_directives_emitted=0 ;; esac
    directives_received_total=$((directives_received_total + result_directives_received))
    directives_emitted_total=$((directives_emitted_total + result_directives_emitted))

    if [ -n "$(trim "$result_injection")" ]; then
      injections=$((injections + 1))
    fi

    if [ "$processed_first" -eq 0 ]; then
      processed_json="$processed_json,"
    fi
    processed_first=0

    processed_json="$processed_json{\"mode_id\":\"$(json_escape "$result_mode")\",\"status\":\"$(json_escape "$result_status")\",\"drift_score\":\"$(json_escape "$result_drift")\",\"skills\":$(mr_csv_to_json_array "$result_skills"),\"injected_queue_item\":\"$(json_escape "$result_injection")\",\"directives_received\":\"$(json_escape "$result_directives_received")\",\"directives_emitted\":\"$(json_escape "$result_directives_emitted")\",\"directive_summary\":\"$(json_escape "$result_directive_summary")\"}"
  done <<EOF_DUE
$(sort -t'|' -k1,1nr -k2,2 "$due_mode_order_file")
EOF_DUE
  rm -f "$due_mode_order_file"
  unset MR_QUEUE_SIGNALS_OVERRIDE 2>/dev/null || true

  scheduler_state=$(mr_scheduler_state_file)
  prev_ticks=$(mr_env_get "$scheduler_state" "ticks" "0")
  case "$prev_ticks" in ""|*[!0-9]*) prev_ticks=0 ;; esac
  ticks=$((prev_ticks + 1))
  summary="tick active=$active_modes due=$due_modes injections=$injections directives_in=$directives_received_total directives_out=$directives_emitted_total"
  mr_env_set "$scheduler_state" "last_tick" "$now_epoch"
  mr_env_set "$scheduler_state" "last_tick_iso" "$now_iso"
  mr_env_set "$scheduler_state" "ticks" "$ticks"
  mr_env_set "$scheduler_state" "last_due_modes" "$due_modes"
  mr_env_set "$scheduler_state" "last_injections" "$injections"
  mr_env_set "$scheduler_state" "last_directives_received" "$directives_received_total"
  mr_env_set "$scheduler_state" "last_directives_emitted" "$directives_emitted_total"
  mr_env_set "$scheduler_state" "last_summary" "$summary"

  printf '{"timestamp":"%s","active_modes":%s,"due_modes":%s,"injections":%s,"directives_received":%s,"directives_emitted":%s,"processed":[%s],"summary":"%s"}' \
    "$(json_escape "$now_iso")" "$active_modes" "$due_modes" "$injections" "$directives_received_total" "$directives_emitted_total" "$processed_json" "$(json_escape "$summary")"
}

mr_mode_json_array() {
  printf '['
  first=1
  for mode_id in $(mr_list_mode_ids); do
    manifest_file=$(mr_mode_manifest_file "$mode_id")
    state_file=$(mr_mode_state_file "$mode_id")

    mode_name=$(mr_env_get "$manifest_file" "name" "$mode_id")
    mode_desc=$(mr_env_get "$manifest_file" "description" "")
    mode_priority=$(mr_env_get "$state_file" "priority" "$(mr_env_get "$manifest_file" "default_priority" "5")")
    mode_cadence=$(mr_env_get "$state_file" "cadence_sec" "$(mr_env_get "$manifest_file" "default_cadence_sec" "900")")
    mode_enabled=$(mr_bool_norm "$(mr_env_get "$state_file" "enabled" "0")")
    mode_interrupt=$(mr_bool_norm "$(mr_env_get "$state_file" "interrupt_rights" "$(mr_env_get "$manifest_file" "default_interrupt_rights" "0")")")
    mode_queue_injection=$(mr_bool_norm "$(mr_env_get "$state_file" "allow_queue_injection" "0")")
    mode_status=$(mr_env_get "$state_file" "status" "idle")
    mode_drift=$(mr_env_get "$state_file" "drift_score" "0.00")
    mode_last_tick=$(mr_env_get "$state_file" "last_tick" "0")
    mode_next_tick=$(mr_env_get "$state_file" "next_tick" "0")
    mode_goal=$(mr_env_get "$state_file" "goal_state" "")
    mode_skills=$(mr_env_get "$state_file" "last_skill_plan" "")
    mode_directive_count=$(mr_env_get "$state_file" "last_directive_count" "0")
    mode_directive_emits=$(mr_env_get "$state_file" "last_directive_emits" "0")
    mode_directive_summary=$(mr_env_get "$state_file" "last_directive_summary" "none")
    mode_subs=$(mr_mode_subscriptions_current "$mode_id")
    mode_caps=$(mr_env_get "$manifest_file" "allowed_capabilities" "")

    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0

    printf '{"id":"%s","name":"%s","description":"%s","enabled":%s,"priority":%s,"cadence_sec":%s,"interrupt_rights":%s,"allow_queue_injection":%s,"status":"%s","drift_score":"%s","last_tick":"%s","next_tick":"%s","goal_state":"%s","last_skill_plan":%s,"last_directive_count":"%s","last_directive_emits":"%s","last_directive_summary":"%s","telemetry_subscriptions":%s,"allowed_capabilities":%s}' \
      "$(json_escape "$mode_id")" \
      "$(json_escape "$mode_name")" \
      "$(json_escape "$mode_desc")" \
      "$mode_enabled" \
      "$(mr_positive_int_or "$mode_priority" "5")" \
      "$(mr_positive_int_or "$mode_cadence" "900")" \
      "$mode_interrupt" \
      "$mode_queue_injection" \
      "$(json_escape "$mode_status")" \
      "$(json_escape "$mode_drift")" \
      "$(json_escape "$mode_last_tick")" \
      "$(json_escape "$mode_next_tick")" \
      "$(json_escape "$mode_goal")" \
      "$(mr_csv_to_json_array "$mode_skills")" \
      "$(json_escape "$mode_directive_count")" \
      "$(json_escape "$mode_directive_emits")" \
      "$(json_escape "$mode_directive_summary")" \
      "$(mr_csv_to_json_array "$mode_subs")" \
      "$(mr_csv_to_json_array "$mode_caps")"
  done
  printf ']'
}

mr_skill_json_array() {
  printf '['
  first=1
  for skill_id in $(mr_list_skill_ids); do
    meta_file=$(mr_skill_meta_file "$skill_id")
    skill_name=$(mr_env_get "$meta_file" "name" "$skill_id")
    skill_trigger=$(mr_env_get "$meta_file" "trigger" "")
    skill_caps=$(mr_env_get "$meta_file" "capabilities" "")
    skill_desc=$(mr_env_get "$meta_file" "description" "")

    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0

    printf '{"id":"%s","name":"%s","description":"%s","trigger":"%s","capabilities":%s,"stateless":true,"interrupt_authority":false,"files":{"policy_md":true,"trigger_yaml":true,"tools_json":true,"output_schema_json":true}}' \
      "$(json_escape "$skill_id")" \
      "$(json_escape "$skill_name")" \
      "$(json_escape "$skill_desc")" \
      "$(json_escape "$skill_trigger")" \
      "$(mr_csv_to_json_array "$skill_caps")"
  done
  printf ']'
}

mr_dashboard_panels_json() {
  scheduler_state=$(mr_scheduler_state_file)
  sched_last_tick=$(mr_env_get "$scheduler_state" "last_tick_iso" "")
  sched_summary=$(mr_env_get "$scheduler_state" "last_summary" "")

  metrics=$(mr_queue_metrics)
  pending=$(printf '%s\n' "$metrics" | sed -n 's/^pending=//p' | sed -n '1p')
  running=$(printf '%s\n' "$metrics" | sed -n 's/^running=//p' | sed -n '1p')
  errors=$(printf '%s\n' "$metrics" | sed -n 's/^errors=//p' | sed -n '1p')

  active_modes=0
  for mode_id in $(mr_list_mode_ids); do
    enabled=$(mr_bool_norm "$(mr_env_get "$(mr_mode_state_file "$mode_id")" "enabled" "0")")
    if [ "$enabled" = "1" ]; then
      active_modes=$((active_modes + 1))
    fi
  done

  printf '['
  printf '{"id":"global-dashboard","title":"Global Dashboard","summary":"Unified multi-mode telemetry overview.","metrics":[{"label":"Active modes","value":"%s"},{"label":"Queue pending","value":"%s"},{"label":"Queue running","value":"%s"},{"label":"Queue errors","value":"%s"}],"stream":"%s"},' \
    "$(json_escape "$active_modes")" "$(json_escape "$pending")" "$(json_escape "$running")" "$(json_escape "$errors")" "$(json_escape "$sched_summary")"

  printf '{"id":"oracle-intel-panel","title":"Oracle / Intel Panel","summary":"Watchtower and calibration signals for situational awareness.","metrics":[{"label":"Semantic drift","value":"tracked"},{"label":"Calibration","value":"longitudinal"}],"stream":"%s"},' \
    "$(json_escape "Last scheduler tick: ${sched_last_tick:-n/a}")"

  printf '{"id":"grant-income-panel","title":"Grant / Income Panel","summary":"Funding task surfacing with optional autonomous queue injection.","metrics":[{"label":"Queue injection","value":"mode-gated"},{"label":"Authorization","value":"required"}],"stream":"%s"},' \
    "$(json_escape "Enable queue injection on selected modes for autonomous task insertion.")"

  printf '{"id":"reputation-monitoring-panel","title":"Reputation Monitoring Panel","summary":"Signal-cost and sentiment pressure tracking.","metrics":[{"label":"Reputation mode","value":"available"},{"label":"Compliance gate","value":"active"}],"stream":"%s"}' \
    "$(json_escape "Use Reputation Thermostat + Compliance modes for guarded outreach.")"
  printf ']'
}

mr_mode_pending_directive_count() {
  mode_id=$1
  inbox_file=$(mr_mode_directive_inbox_file "$mode_id")
  cursor_file=$(mr_mode_directive_cursor_file "$mode_id")
  total_lines=0
  cursor_line=0
  if [ -f "$inbox_file" ]; then
    total_lines=$(wc -l < "$inbox_file" 2>/dev/null | tr -d '[:space:]' || printf '0')
  fi
  if [ -f "$cursor_file" ]; then
    cursor_line=$(read_file_line "$cursor_file" "0")
  fi
  case "$total_lines" in ""|*[!0-9]*) total_lines=0 ;; esac
  case "$cursor_line" in ""|*[!0-9]*) cursor_line=0 ;; esac
  pending=$((total_lines - cursor_line))
  if [ "$pending" -lt 0 ]; then
    pending=0
  fi
  printf '%s' "$pending"
}

mr_cooperation_pending_stats() {
  pending_total=0
  modes_with_pending=0
  for mode_id in $(mr_list_mode_ids); do
    mode_pending=$(mr_mode_pending_directive_count "$mode_id")
    case "$mode_pending" in ""|*[!0-9]*) mode_pending=0 ;; esac
    pending_total=$((pending_total + mode_pending))
    if [ "$mode_pending" -gt 0 ]; then
      modes_with_pending=$((modes_with_pending + 1))
    fi
  done
  printf '%s|%s' "$pending_total" "$modes_with_pending"
}

mr_cooperation_recent_json() {
  max_rows=$1
  case "$max_rows" in ""|*[!0-9]*) max_rows=20 ;; esac
  if [ "$max_rows" -lt 1 ]; then
    max_rows=1
  fi
  coop_log=$(mr_cooperation_log_file)
  printf '['
  first=1
  if [ -f "$coop_log" ]; then
    recent_file=$(mktemp)
    tail -n "$max_rows" "$coop_log" > "$recent_file" 2>/dev/null || : > "$recent_file"
    now_epoch=$(mr_now_epoch)
    case "$now_epoch" in ""|*[!0-9]*) now_epoch=0 ;; esac
    while IFS="$(printf '\t')" read -r event_epoch event_iso from_mode to_mode event_kind event_priority event_payload expires_epoch || [ -n "$event_epoch$event_kind$event_payload" ]; do
      [ -n "$(trim "$event_kind")" ] || continue
      case "$expires_epoch" in ""|*[!0-9]*) expires_epoch=0 ;; esac
      expired=false
      if [ "$expires_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ] && [ "$expires_epoch" -lt "$now_epoch" ]; then
        expired=true
      fi
      if [ "$first" -eq 0 ]; then
        printf ','
      fi
      first=0
      printf '{"timestamp":"%s","from_mode":"%s","to_mode":"%s","kind":"%s","priority":"%s","payload":"%s","expires_epoch":"%s","expired":%s}' \
        "$(json_escape "$event_iso")" \
        "$(json_escape "$from_mode")" \
        "$(json_escape "$to_mode")" \
        "$(json_escape "$event_kind")" \
        "$(json_escape "$event_priority")" \
        "$(json_escape "$event_payload")" \
        "$(json_escape "$expires_epoch")" \
        "$expired"
    done < "$recent_file"
    rm -f "$recent_file"
  fi
  printf ']'
}

mode_runtime_state_json() {
  scheduler_state=$(mr_scheduler_state_file)
  last_tick=$(mr_env_get "$scheduler_state" "last_tick" "0")
  last_tick_iso=$(mr_env_get "$scheduler_state" "last_tick_iso" "")
  ticks=$(mr_env_get "$scheduler_state" "ticks" "0")
  due_modes=$(mr_env_get "$scheduler_state" "last_due_modes" "0")
  injections=$(mr_env_get "$scheduler_state" "last_injections" "0")
  directives_received=$(mr_env_get "$scheduler_state" "last_directives_received" "0")
  directives_emitted=$(mr_env_get "$scheduler_state" "last_directives_emitted" "0")
  summary=$(mr_env_get "$scheduler_state" "last_summary" "Scheduler idle")
  cooperation_stats=$(mr_cooperation_pending_stats)
  cooperation_pending_total=$(printf '%s' "$cooperation_stats" | cut -d'|' -f1)
  cooperation_modes_pending=$(printf '%s' "$cooperation_stats" | cut -d'|' -f2)
  cooperation_recent=$(mr_cooperation_recent_json "24")

  printf '{"scheduler":{"last_tick":"%s","last_tick_iso":"%s","ticks":"%s","last_due_modes":"%s","last_injections":"%s","last_directives_received":"%s","last_directives_emitted":"%s","summary":"%s"},"modes":%s,"skills":%s,"panels":%s,"cooperation":{"pending_total":"%s","modes_with_pending":"%s","recent":%s}}' \
    "$(json_escape "$last_tick")" \
    "$(json_escape "$last_tick_iso")" \
    "$(json_escape "$ticks")" \
    "$(json_escape "$due_modes")" \
    "$(json_escape "$injections")" \
    "$(json_escape "$directives_received")" \
    "$(json_escape "$directives_emitted")" \
    "$(json_escape "$summary")" \
    "$(mr_mode_json_array)" \
    "$(mr_skill_json_array)" \
    "$(mr_dashboard_panels_json)" \
    "$(json_escape "$cooperation_pending_total")" \
    "$(json_escape "$cooperation_modes_pending")" \
    "$cooperation_recent"
}

mr_skill_capabilities() {
  skill_id=$1
  meta_file=$(mr_skill_meta_file "$skill_id")
  mr_env_get "$meta_file" "capabilities" ""
}

mr_skill_artifact_targets_json() {
  skill_id=$1
  artifacts="policy.md,trigger.yaml,tools.json,output.schema.json"
  case "$skill_id" in
    shadow-documentation)
      artifacts="$artifacts,README.md,.architecture.md,.tasks/index.md"
      ;;
    dashboard-builder|panel-integrator)
      artifacts="$artifacts,dashboard/composites.md,telemetry/*.log"
      ;;
    proceduralization)
      artifacts="$artifacts,scripts/*.sh,runbook.md"
      ;;
    compliance-lookup|contract-analyzer)
      artifacts="$artifacts,compliance-notes.md"
      ;;
    codegen-infra-spin-up)
      artifacts="$artifacts,infrastructure/*,deployment-checklist.md"
      ;;
  esac
  mr_csv_to_json_array "$artifacts"
}

mr_skill_risk_gate() {
  input_text=$1
  input_lower=$(printf '%s' "$input_text" | tr '[:upper:]' '[:lower:]')
  if printf '%s' "$input_lower" | grep -Eq 'phish|malware|credential stuffing|ddos|ransomware|exploit( chain)?|spam campaign|bypass paywall|steal credentials|fraud'; then
    printf '%s' "blocked"
    return 0
  fi
  if printf '%s' "$input_lower" | grep -Eq 'contact real|email customers|cold outreach|post publicly|publish live|charge card|payment|register company|legal filing|file taxes|sign contract'; then
    printf '%s' "needs_auth"
    return 0
  fi
  printf '%s' "ok"
}

mr_skill_dynamic_step() {
  input_text=$1
  input_lower=$(printf '%s' "$input_text" | tr '[:upper:]' '[:lower:]')
  if printf '%s' "$input_lower" | grep -Eq 'deterministic|replay|checksum|regression|test'; then
    printf '%s' "Attach deterministic checks, replay criteria, and pass/fail thresholds"
    return 0
  fi
  if printf '%s' "$input_lower" | grep -Eq 'dashboard|panel|telemetry|metric'; then
    printf '%s' "Publish telemetry mapping and panel acceptance criteria"
    return 0
  fi
  if printf '%s' "$input_lower" | grep -Eq 'contract|legal|compliance|policy'; then
    printf '%s' "Capture obligations and map each to an enforceable control"
    return 0
  fi
  if printf '%s' "$input_lower" | grep -Eq 'market|customer|demand|competition|pricing'; then
    printf '%s' "Document evidence quality, confidence, and open uncertainty"
    return 0
  fi
  printf '%s' "Capture measurable acceptance criteria and explicit stop conditions"
}

mr_skill_actuator_output_json() {
  skill_id=$1
  mode_id=$2
  input_text=$3

  clean_input=$(mr_sanitize_inline "$input_text")
  [ -n "$clean_input" ] || clean_input="No explicit input provided."
  mode_focus=$(mr_mode_focus_text "$mode_id")
  risk_gate=$(mr_skill_risk_gate "$clean_input")
  governance_gate="none"
  status_value="ok"
  required_followup=false

  case "$risk_gate" in
    blocked)
      status_value="blocked"
      governance_gate="blocked"
      required_followup=true
      ;;
    needs_auth)
      status_value="needs_auth"
      governance_gate="approval_required"
      required_followup=true
      ;;
  esac

  actions=""
  case "$skill_id" in
    proceduralization)
      actions='Capture successful manual workflow; Normalize into reusable pipeline stages; Generate script/runbook template; Define regression guardrails for reuse'
      ;;
    grant-hunter)
      actions='Scan funding channels; Score opportunities by fit and effort; Draft submission skeleton with milestones; Generate dependency checklist'
      ;;
    negotiation-doppelganger)
      actions='Model counterpart positions; Build BATNA/threshold tree; Generate negotiation script variants; Identify concession boundaries'
      ;;
    devils-liquidity-provider)
      actions='Detect current stall point; Propose substitute execution path; Re-sequence queue to recover momentum; Define rollback route'
      ;;
    shadow-documentation)
      actions='Diff changed artifacts; Update README/ops notes; Refresh architecture map and task index; Add concise changelog entry'
      ;;
    latent-opportunity-harvester)
      actions='Run cross-domain scan; Surface complementarities and slack; Rank leverage opportunities; Emit shortlist with rationale'
      ;;
    dashboard-builder)
      actions='Define panel modules and contracts; Attach telemetry streams; Emit composable dashboard config; Add freshness/latency indicators'
      ;;
    agent-spawner)
      actions='Validate spawn scope and boundaries; Select agent template; Emit child-agent bootstrap contract; Define supervision and stop criteria'
      ;;
    panel-integrator)
      actions='Bind multi-agent feeds; Normalize metric taxonomy; Publish unified panel view; Add source lineage metadata'
      ;;
    compliance-lookup)
      actions='Locate governing constraints; Extract actionable obligations; Flag uncertainty and jurisdictional gaps; Propose control mapping'
      ;;
    report-synthesizer)
      actions='Collect distributed outputs; Build sectioned narrative; Emit concise recommendations; Add residual-risk and confidence section'
      ;;
    market-research)
      actions='Define market slice and hypotheses; Gather demand signals; Summarize competitor posture; Estimate confidence and unknowns'
      ;;
    contract-analyzer)
      actions='Parse contract clauses; Extract obligations and risk surfaces; Summarize red flags; Recommend mitigation follow-ups'
      ;;
    pitch-drafter)
      actions='Identify target audience; Tailor value narrative; Draft pitch variants; Align with likely objections'
      ;;
    data-etl)
      actions='Ingest source payload; Normalize schema and typing; Route transformed output; Emit data quality diagnostics'
      ;;
    web-scraper)
      actions='Fetch policy-approved sources; Extract target fields; Emit structured dataset; Log provenance and extraction quality'
      ;;
    simulation-runner)
      actions='Define scenario bounds and assumptions; Execute bounded simulations; Report outcome distributions; Highlight failure envelopes'
      ;;
    codegen-infra-spin-up)
      actions='Generate infrastructure scaffolds; Validate baseline configuration; Produce deployment checklist; Add rollback and observability stubs'
      ;;
    *)
      actions='Parse request; Execute bounded task; Emit structured output; Capture next-action handoff'
      ;;
  esac

  if [ "$risk_gate" = "blocked" ]; then
    actions='Refuse unsafe objective; Explain blocked safety category; Offer compliant alternatives; Request safe objective rewrite'
  fi
  if [ "$risk_gate" = "needs_auth" ]; then
    actions="$actions; Request explicit authorization before irreversible external actions"
  fi
  dynamic_step=$(mr_skill_dynamic_step "$clean_input")
  actions="$actions; $dynamic_step"
  actions_json=$(mr_csv_to_json_array "$(printf '%s' "$actions" | sed 's/;\s*/,/g')")

  bundle_health="complete"
  missing_files=""
  skill_dir=$(mr_skill_dir_for "$skill_id")
  for required_file in policy.md trigger.yaml tools.json output.schema.json; do
    if [ ! -f "$skill_dir/$required_file" ]; then
      bundle_health="partial"
      if [ -n "$missing_files" ]; then
        missing_files="$missing_files,$required_file"
      else
        missing_files="$required_file"
      fi
    fi
  done
  missing_json=$(mr_csv_to_json_array "$missing_files")

  confidence="0.82"
  if [ "$bundle_health" = "partial" ]; then
    confidence="0.68"
  fi
  if [ "$status_value" = "needs_auth" ]; then
    confidence="0.55"
  elif [ "$status_value" = "blocked" ]; then
    confidence="0.20"
  fi

  artifacts_json=$(mr_skill_artifact_targets_json "$skill_id")
  summary_text="Executed $skill_id under mode ${mode_id:-assistant} with focus on $mode_focus. Objective: $clean_input"
  if [ "$status_value" = "needs_auth" ]; then
    summary_text="Prepared bounded plan for $skill_id, but explicit authorization is required for irreversible external actions."
  elif [ "$status_value" = "blocked" ]; then
    summary_text="Blocked unsafe request for $skill_id and generated compliant alternatives."
  fi

  notes_text="Stateless run completed; scratch memory disposed. Governance gate=$governance_gate. Bundle health=$bundle_health."

  printf '{"skill_id":"%s","status":"%s","summary":"%s","actions":%s,"artifacts":%s,"mode_focus":"%s","governance_gate":"%s","bundle_health":"%s","missing_bundle_files":%s,"required_followup":%s,"confidence":"%s","notes":"%s"}' \
    "$(json_escape "$skill_id")" \
    "$(json_escape "$status_value")" \
    "$(json_escape "$summary_text")" \
    "$actions_json" \
    "$artifacts_json" \
    "$(json_escape "$mode_focus")" \
    "$(json_escape "$governance_gate")" \
    "$(json_escape "$bundle_health")" \
    "$missing_json" \
    "$required_followup" \
    "$(json_escape "$confidence")" \
    "$(json_escape "$notes_text")"
}

mr_skill_invoke_json() {
  mode_id=$1
  skill_id=$2
  input_text=$3
  requested_caps=$4

  if [ -z "$(trim "$mode_id")" ]; then
    mode_id="assistant"
  fi

  if ! mr_skill_exists "$skill_id"; then
    printf '{"success":false,"error":"skill not found"}'
    return 0
  fi

  skill_caps=$(mr_skill_capabilities "$skill_id")
  caps_to_check=$skill_caps
  if [ -n "$(trim "$requested_caps")" ]; then
    caps_to_check=$(mr_csv_normalize "$requested_caps")
  fi

  sensitive_caps=""
  old_ifs=$IFS
  IFS=','
  for cap in $caps_to_check; do
    clean=$(trim "$cap")
    [ -n "$clean" ] || continue
    case "$clean" in
      filesystem|network|agent_spawn)
        if [ -z "$sensitive_caps" ]; then
          sensitive_caps="$clean"
        else
          sensitive_caps="$sensitive_caps,$clean"
        fi
        ;;
    esac
  done
  IFS=$old_ifs

  if [ -n "$(trim "$sensitive_caps")" ]; then
    if [ "$mode_id" = "assistant" ]; then
      printf '{"success":false,"error":"mode authorization required for requested capabilities","required_capabilities":%s}' "$(mr_csv_to_json_array "$sensitive_caps")"
      return 0
    fi
    if ! mr_mode_exists "$mode_id"; then
      printf '{"success":false,"error":"mode not found for authorization"}'
      return 0
    fi
    if ! mr_mode_authorizes_capabilities "$mode_id" "$sensitive_caps"; then
      printf '{"success":false,"error":"mode policy does not authorize requested capabilities","requested_capabilities":%s,"allowed_capabilities":%s}' \
        "$(mr_csv_to_json_array "$sensitive_caps")" "$(mr_csv_to_json_array "$(mr_mode_allowed_capabilities "$mode_id")")"
      return 0
    fi
  fi

  invocation_id=$(new_id)
  invocation_dir="$(mr_bus_dir)/$invocation_id"
  scratch_dir="$invocation_dir/scratch"
  mkdir -p "$scratch_dir"

  request_file="$invocation_dir/request.txt"
  result_file="$invocation_dir/result.json"
  metadata_file="$invocation_dir/metadata.env"
  started_iso=$(mr_now_iso)

  {
    printf 'mode_id=%s\n' "$mode_id"
    printf 'skill_id=%s\n' "$skill_id"
    printf 'requested_capabilities=%s\n' "$(mr_csv_normalize "$caps_to_check")"
    printf 'started=%s\n' "$started_iso"
  } > "$metadata_file"

  printf '%s\n' "$input_text" > "$request_file"

  result_json=$(mr_skill_actuator_output_json "$skill_id" "$mode_id" "$input_text")
  printf '%s\n' "$result_json" > "$result_file"
  result_status=$(json_extract_string_field "status" "$result_json" || true)
  [ -n "$(trim "$result_status")" ] || result_status="ok"
  result_gate=$(json_extract_string_field "governance_gate" "$result_json" || true)
  [ -n "$(trim "$result_gate")" ] || result_gate="none"

  rm -rf "$scratch_dir"

  finished_iso=$(mr_now_iso)
  mr_env_set "$metadata_file" "finished" "$finished_iso"
  mr_env_set "$metadata_file" "scratch_disposed" "1"

  if [ "$mode_id" != "assistant" ] && mr_mode_exists "$mode_id"; then
    mode_events_file=$(mr_mode_event_queue_file "$mode_id")
    printf '%s\tinvocation=%s\tskill=%s\tstatus=%s\tgate=%s\n' "$finished_iso" "$invocation_id" "$skill_id" "$result_status" "$result_gate" >> "$mode_events_file"
  fi

  printf '{"success":true,"invocation":{"id":"%s","mode_id":"%s","skill_id":"%s","requested_capabilities":%s,"scratch_persistent":false,"started":"%s","finished":"%s"},"result":%s}' \
    "$(json_escape "$invocation_id")" \
    "$(json_escape "$mode_id")" \
    "$(json_escape "$skill_id")" \
    "$(mr_csv_to_json_array "$caps_to_check")" \
    "$(json_escape "$started_iso")" \
    "$(json_escape "$finished_iso")" \
    "$result_json"
}

mr_mode_update_json() {
  mode_id=$(trim "$(param "mode_id")")
  if ! valid_id "$mode_id"; then
    printf '{"success":false,"error":"invalid mode_id"}'
    return 0
  fi
  if ! mr_mode_exists "$mode_id"; then
    printf '{"success":false,"error":"mode not found"}'
    return 0
  fi

  state_file=$(mr_mode_state_file "$mode_id")

  enabled_raw=$(trim "$(param "enabled")")
  cadence_raw=$(trim "$(param "cadence_sec")")
  priority_raw=$(trim "$(param "priority")")
  interrupt_raw=$(trim "$(param "interrupt_rights")")
  queue_injection_raw=$(trim "$(param "allow_queue_injection")")
  goal_raw=$(param "goal_state")
  subscriptions_raw=$(param "subscriptions")

  if [ -n "$enabled_raw" ]; then
    mr_env_set "$state_file" "enabled" "$(mr_bool_norm "$enabled_raw")"
  fi
  if [ -n "$cadence_raw" ]; then
    mr_env_set "$state_file" "cadence_sec" "$(mr_positive_int_or "$cadence_raw" "900")"
  fi
  if [ -n "$priority_raw" ]; then
    mr_env_set "$state_file" "priority" "$(mr_positive_int_or "$priority_raw" "5")"
  fi
  if [ -n "$interrupt_raw" ]; then
    mr_env_set "$state_file" "interrupt_rights" "$(mr_bool_norm "$interrupt_raw")"
  fi
  if [ -n "$queue_injection_raw" ]; then
    mr_env_set "$state_file" "allow_queue_injection" "$(mr_bool_norm "$queue_injection_raw")"
  fi
  if [ -n "$(trim "$goal_raw")" ]; then
    clean_goal=$(mr_sanitize_inline "$goal_raw")
    mr_env_set "$state_file" "goal_state" "$clean_goal"
    printf '# Goal State\n\n- %s\n' "$clean_goal" > "$(mr_mode_goal_file "$mode_id")"
  fi
  if [ -n "$(trim "$subscriptions_raw")" ]; then
    printf '%s\n' "$(mr_csv_normalize "$subscriptions_raw")" > "$(mr_mode_subscriptions_file "$mode_id")"
  fi

  printf '{"success":true,"mode_id":"%s","mode_runtime":%s}' "$(json_escape "$mode_id")" "$(mode_runtime_state_json)"
}

mr_mode_runtime_state_response() {
  printf '{"success":true,"mode_runtime":%s}\n' "$(mode_runtime_state_json)"
}

mr_mode_runtime_tick_response() {
  workspace_id=$(trim "$(param "workspace_id")")
  conversation_id=$(trim "$(param "conversation_id")")
  if [ -n "$workspace_id" ] && ! valid_id "$workspace_id"; then
    printf '{"success":false,"error":"invalid workspace_id"}\n'
    return 0
  fi
  if [ -n "$conversation_id" ] && ! valid_id "$conversation_id"; then
    printf '{"success":false,"error":"invalid conversation_id"}\n'
    return 0
  fi

  tick_json=$(mr_mode_scheduler_tick_json "$workspace_id" "$conversation_id")
  printf '{"success":true,"tick":%s,"mode_runtime":%s}\n' "$tick_json" "$(mode_runtime_state_json)"
}

mr_mode_runtime_skill_invoke_response() {
  mode_id=$(trim "$(param "mode_id")")
  skill_id=$(trim "$(param "skill_id")")
  input_text=$(param "input")
  requested_caps=$(param "capabilities")

  if [ -z "$skill_id" ]; then
    printf '{"success":false,"error":"skill_id is required"}\n'
    return 0
  fi

  mr_skill_invoke_json "$mode_id" "$skill_id" "$input_text" "$requested_caps"
  printf '\n'
}

mr_skill_name_from_trigger_file() {
  trigger_file=$1
  if [ ! -f "$trigger_file" ]; then
    printf '%s' ""
    return 0
  fi
  parsed=$(sed -n 's/^name:[[:space:]]*"\{0,1\}\(.*\)"\{0,1\}[[:space:]]*$/\1/p' "$trigger_file" | sed -n '1p')
  parsed=$(trim "$parsed")
  printf '%s' "$(mr_sanitize_inline "$parsed")"
}

mr_skill_trigger_from_trigger_file() {
  trigger_file=$1
  if [ ! -f "$trigger_file" ]; then
    printf '%s' ""
    return 0
  fi
  parsed=$(sed -n 's/^[[:space:]]*-[[:space:]]*"\{0,1\}\(.*\)"\{0,1\}[[:space:]]*$/\1/p' "$trigger_file" | sed -n '1p')
  parsed=$(trim "$parsed")
  printf '%s' "$(mr_sanitize_inline "$parsed")"
}

mr_skill_caps_from_tools_file() {
  tools_file=$1
  if [ ! -f "$tools_file" ]; then
    printf '%s' ""
    return 0
  fi
  raw=$(tr -d '\n\r' < "$tools_file" | sed -n 's/.*"tools"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | sed -n '1p')
  if [ -z "$(trim "$raw")" ]; then
    printf '%s' ""
    return 0
  fi
  normalized=$(printf '%s' "$raw" | tr '"' ' ' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed '/^$/d' | paste -sd, -)
  printf '%s' "$(mr_csv_normalize "$normalized")"
}

mr_skill_description_from_policy_file() {
  policy_file=$1
  if [ ! -f "$policy_file" ]; then
    printf '%s' ""
    return 0
  fi
  parsed=$(awk 'NF { if ($0 ~ /^#/) next; print; exit }' "$policy_file")
  parsed=$(trim "$parsed")
  printf '%s' "$(mr_sanitize_inline "$parsed")"
}

mr_mode_runtime_skill_create_response() {
  skill_id=$(trim "$(param "skill_id")")
  skill_name=$(trim "$(param "name")")
  trigger_text=$(trim "$(param "trigger")")
  capabilities=$(trim "$(param "capabilities")")
  description_text=$(trim "$(param "description")")

  skill_id=$(printf '%s' "$skill_id" | tr '[:upper:]' '[:lower:]')
  if ! valid_id "$skill_id"; then
    printf '{"success":false,"error":"invalid skill_id"}\n'
    return 0
  fi
  if mr_skill_exists "$skill_id"; then
    printf '{"success":false,"error":"skill already exists"}\n'
    return 0
  fi
  if [ -z "$skill_name" ]; then
    skill_name=$skill_id
  fi
  if [ -z "$trigger_text" ]; then
    trigger_text="when manually invoked"
  fi
  if [ -z "$capabilities" ]; then
    capabilities="filesystem"
  fi
  if [ -z "$description_text" ]; then
    description_text="Custom skill bundle created from the Artificer skill manager."
  fi

  mr_seed_skill_bundle "$skill_id" "$skill_name" "$trigger_text" "$capabilities" "$description_text"
  printf '{"success":true,"skill_id":"%s","mode_runtime":%s}\n' "$(json_escape "$skill_id")" "$(mode_runtime_state_json)"
}

mr_mode_runtime_skill_install_response() {
  source_path=$(trim "$(param "source_path")")
  skill_id_raw=$(trim "$(param "skill_id")")
  replace_raw=$(trim "$(param "replace")")
  replace_existing=$(mr_bool_norm "$replace_raw")

  if [ -z "$source_path" ]; then
    printf '{"success":false,"error":"source_path is required"}\n'
    return 0
  fi
  if [ ! -d "$source_path" ]; then
    printf '{"success":false,"error":"source_path is not a directory"}\n'
    return 0
  fi

  skill_id=$skill_id_raw
  if [ -z "$skill_id" ]; then
    skill_id=$(basename "$source_path")
  fi
  skill_id=$(printf '%s' "$skill_id" | tr '[:upper:]' '[:lower:]')
  if ! valid_id "$skill_id"; then
    printf '{"success":false,"error":"invalid skill_id"}\n'
    return 0
  fi

  target_dir=$(mr_skill_dir_for "$skill_id")
  if mr_skill_exists "$skill_id" && [ "$replace_existing" != "1" ]; then
    printf '{"success":false,"error":"skill already exists (set replace=1 to overwrite)"}\n'
    return 0
  fi

  missing=""
  for required_file in policy.md trigger.yaml tools.json output.schema.json; do
    if [ ! -f "$source_path/$required_file" ]; then
      if [ -n "$missing" ]; then
        missing="$missing,$required_file"
      else
        missing="$required_file"
      fi
    fi
  done
  if [ -n "$missing" ]; then
    printf '{"success":false,"error":"source bundle is missing required files","missing":%s}\n' "$(mr_csv_to_json_array "$missing")"
    return 0
  fi

  source_policy="$source_path/policy.md"
  source_trigger="$source_path/trigger.yaml"
  source_tools="$source_path/tools.json"
  source_schema="$source_path/output.schema.json"

  skill_name=$(mr_skill_name_from_trigger_file "$source_trigger")
  trigger_text=$(mr_skill_trigger_from_trigger_file "$source_trigger")
  capabilities=$(mr_skill_caps_from_tools_file "$source_tools")
  description_text=$(mr_skill_description_from_policy_file "$source_policy")

  if [ -z "$skill_name" ]; then
    skill_name=$skill_id
  fi
  if [ -z "$trigger_text" ]; then
    trigger_text="when manually invoked"
  fi
  if [ -z "$capabilities" ]; then
    capabilities="filesystem"
  fi
  if [ -z "$description_text" ]; then
    description_text="Installed external skill bundle."
  fi

  if [ "$replace_existing" = "1" ] && [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
  fi

  mr_seed_skill_bundle "$skill_id" "$skill_name" "$trigger_text" "$capabilities" "$description_text"
  cp "$source_policy" "$target_dir/policy.md"
  cp "$source_trigger" "$target_dir/trigger.yaml"
  cp "$source_tools" "$target_dir/tools.json"
  cp "$source_schema" "$target_dir/output.schema.json"

  meta_file=$(mr_skill_meta_file "$skill_id")
  {
    printf 'id=%s\n' "$skill_id"
    printf 'name=%s\n' "$(mr_sanitize_inline "$skill_name")"
    printf 'trigger=%s\n' "$(mr_sanitize_inline "$trigger_text")"
    printf 'capabilities=%s\n' "$(mr_csv_normalize "$capabilities")"
    printf 'description=%s\n' "$(mr_sanitize_inline "$description_text")"
    printf 'stateless=1\n'
    printf 'interrupt_authority=0\n'
  } > "$meta_file"

  printf '{"success":true,"skill_id":"%s","replaced":%s,"mode_runtime":%s}\n' \
    "$(json_escape "$skill_id")" \
    "$( [ "$replace_existing" = "1" ] && printf 'true' || printf 'false' )" \
    "$(mode_runtime_state_json)"
}
