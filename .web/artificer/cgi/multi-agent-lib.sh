#!/bin/sh

ma_target_type_is_valid() {
  case "$1" in
    Action|Charter|Ontology|Commitment|Workspace|Resident|Interpretation|Procedure|Flow)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

ma_escalation_class_is_valid() {
  case "$1" in
    PolicyTradeoff|OntologicalMisfit|EpistemicRisk|LockInRisk|CaptureRisk|IdentityDrift|DiversityRisk|RestraintOpportunity|SalienceExpansion|StrategicPreemption|StrategicFieldCreation|CognitiveEnvironment|SelectionEnvironment)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

ma_target_type_enum_json() {
  printf '[\"Action\",\"Charter\",\"Ontology\",\"Commitment\",\"Workspace\",\"Resident\",\"Interpretation\",\"Procedure\",\"Flow\"]'
}

ma_escalation_class_enum_json() {
  printf '[\"PolicyTradeoff\",\"OntologicalMisfit\",\"EpistemicRisk\",\"LockInRisk\",\"CaptureRisk\",\"IdentityDrift\",\"DiversityRisk\",\"RestraintOpportunity\",\"SalienceExpansion\",\"StrategicPreemption\",\"StrategicFieldCreation\",\"CognitiveEnvironment\",\"SelectionEnvironment\"]'
}

ma_curated_residents_tsv() {
  cat <<'TSV'
credibility-manager|Credibility Manager|Monitors Commitments and surfaces credibility-related decisions.
continuity-steward|Continuity Steward|Maintains cross-session intention and flags drift.
semantic-watchtower|Semantic Watchtower|Detects semantic drift and conceptual bifurcation risk.
compliance-guardian|Compliance Guardian|Surfaces legal/platform constraint dilemmas before action.
failure-simulator|Failure-Mode Simulator|Stress-tests plans and proposes resilience interventions.
epistemic-calibrator|Epistemic Calibrator|Tracks forecast error and proposes calibration updates.
red-team-twin|Adversarial Red-Team Twin|Generates falsification and exploit hypotheses.
narrative-coherence|Narrative Coherence Engine|Flags terminology drift and coherence breaks.
reputation-thermostat|Reputation Thermostat|Surfaces signal-dilution and trust-risk decisions.
chrono-budgeter|Chrono-Budgeter|Proposes effort allocation changes from lagged ROI.
TSV
}

ma_curated_residents_json() {
  first=1
  printf '['
  ma_curated_residents_tsv | while IFS='|' read -r resident_id resident_name resident_mandate; do
    [ -n "$resident_id" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0
    printf '{"id":"%s","name":"%s","mandate":"%s"}' \
      "$(json_escape "$resident_id")" \
      "$(json_escape "$resident_name")" \
      "$(json_escape "$resident_mandate")"
  done
  printf ']'
}

ma_root_dir() {
  printf '%s/multi_agent' "$data_root"
}

ma_global_policies_dir() {
  printf '%s/policies-global' "$(ma_root_dir)"
}

ma_workspace_dir() {
  workspace_id=$1
  printf '%s/%s/.multi_agent' "$workspaces_dir" "$workspace_id"
}

ma_workspace_residents_dir() {
  workspace_id=$1
  printf '%s/residents' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_proposals_dir() {
  workspace_id=$1
  printf '%s/proposals' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_policies_dir() {
  workspace_id=$1
  printf '%s/policies' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_logs_dir() {
  workspace_id=$1
  printf '%s/logs' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_toggles_file() {
  workspace_id=$1
  printf '%s/toggles' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_charter_file() {
  workspace_id=$1
  printf '%s/charter.md' "$(ma_workspace_dir "$workspace_id")"
}

ma_workspace_interpretation_dir() {
  workspace_id=$1
  printf '%s/interpretation' "$(ma_workspace_logs_dir "$workspace_id")"
}

ma_workspace_commitments_dir() {
  workspace_id=$1
  printf '%s/commitments' "$(ma_workspace_logs_dir "$workspace_id")"
}

ma_workspace_meta_file() {
  workspace_id=$1
  printf '%s/meta' "$(ma_workspace_dir "$workspace_id")"
}

ma_meta_get() {
  file_path=$1
  key=$2
  if [ ! -f "$file_path" ]; then
    printf '%s' ""
    return 0
  fi
  sed -n "s/^${key}=//p" "$file_path" | sed -n '1p'
}

ma_meta_set() {
  file_path=$1
  key=$2
  value=$3
  tmp_file=$(mktemp)
  if [ -f "$file_path" ]; then
    sed "/^${key}=/d" "$file_path" > "$tmp_file"
  fi
  printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
  mv "$tmp_file" "$file_path"
}

ma_workspace_init() {
  workspace_id=$1
  ma_dir=$(ma_workspace_dir "$workspace_id")
  residents_dir=$(ma_workspace_residents_dir "$workspace_id")
  proposals_dir=$(ma_workspace_proposals_dir "$workspace_id")
  policies_dir=$(ma_workspace_policies_dir "$workspace_id")
  logs_dir=$(ma_workspace_logs_dir "$workspace_id")
  interpretation_dir=$(ma_workspace_interpretation_dir "$workspace_id")
  commitments_dir=$(ma_workspace_commitments_dir "$workspace_id")
  toggles_file=$(ma_workspace_toggles_file "$workspace_id")
  charter_file=$(ma_workspace_charter_file "$workspace_id")
  meta_file=$(ma_workspace_meta_file "$workspace_id")

  mkdir -p "$(ma_root_dir)" "$(ma_global_policies_dir)" "$ma_dir" "$residents_dir" "$proposals_dir" "$policies_dir" "$logs_dir" "$interpretation_dir" "$commitments_dir"

  if [ ! -f "$toggles_file" ]; then
    cat > "$toggles_file" <<'EOF_TOGGLES'
dilemma_surfacing=1
amendments=0
interpretation_log=0
commitments=0
attention_policies=0
EOF_TOGGLES
  fi

  if [ ! -f "$charter_file" ]; then
    : > "$charter_file"
  fi

  if [ ! -f "$meta_file" ]; then
    cat > "$meta_file" <<'EOF_META'
ontology_link=
shared_context_workspace_ids=
EOF_META
  fi
}

ma_toggle_value() {
  workspace_id=$1
  key=$2
  default_value=${3:-1}
  toggles_file=$(ma_workspace_toggles_file "$workspace_id")
  value=$(ma_meta_get "$toggles_file" "$key")
  case "$value" in
    0|1) printf '%s' "$value" ;;
    *) printf '%s' "$default_value" ;;
  esac
}

ma_spawn_resident() {
  workspace_id=$1
  resident_id=$2
  visible=${3:-0}
  background=${4:-1}
  reserve_compute=${5:-0}
  model_name=${6:-}

  ma_workspace_init "$workspace_id"
  resident_dir="$(ma_workspace_residents_dir "$workspace_id")/$resident_id"
  resident_meta="$resident_dir/meta"
  mkdir -p "$resident_dir"

  resident_name="$resident_id"
  resident_mandate=""
  while IFS='|' read -r cid cname cmandate; do
    [ -n "$cid" ] || continue
    if [ "$cid" = "$resident_id" ]; then
      resident_name=$cname
      resident_mandate=$cmandate
      break
    fi
  done <<EOF_LIST
$(ma_curated_residents_tsv)
EOF_LIST

  cat > "$resident_meta" <<EOF_META
enabled=1
visible=$visible
background=$background
reserve_compute=$reserve_compute
model=$model_name
name=$resident_name
mandate=$resident_mandate
created=$(date +%s 2>/dev/null || printf '0')
EOF_META
}

ma_update_resident_field() {
  workspace_id=$1
  resident_id=$2
  key=$3
  value=$4
  ma_workspace_init "$workspace_id"
  resident_meta="$(ma_workspace_residents_dir "$workspace_id")/$resident_id/meta"
  [ -f "$resident_meta" ] || return 1
  ma_meta_set "$resident_meta" "$key" "$value"
}

ma_workspace_background_resident_count() {
  workspace_id=$1
  ma_workspace_init "$workspace_id"
  residents_dir=$(ma_workspace_residents_dir "$workspace_id")
  count=0
  for resident_meta in "$residents_dir"/*/meta; do
    [ -f "$resident_meta" ] || continue
    enabled=$(ma_meta_get "$resident_meta" "enabled")
    background=$(ma_meta_get "$resident_meta" "background")
    if [ "$enabled" = "1" ] && [ "$background" = "1" ]; then
      count=$((count + 1))
    fi
  done
  printf '%s' "$count"
}

ma_residents_json_for_workspace() {
  workspace_id=$1
  ma_workspace_init "$workspace_id"
  residents_dir=$(ma_workspace_residents_dir "$workspace_id")
  first=1
  printf '['
  for resident_meta in "$residents_dir"/*/meta; do
    [ -f "$resident_meta" ] || continue
    resident_id=$(basename "$(dirname "$resident_meta")")
    enabled=$(ma_meta_get "$resident_meta" "enabled")
    visible=$(ma_meta_get "$resident_meta" "visible")
    background=$(ma_meta_get "$resident_meta" "background")
    reserve_compute=$(ma_meta_get "$resident_meta" "reserve_compute")
    resident_model=$(ma_meta_get "$resident_meta" "model")
    resident_name=$(ma_meta_get "$resident_meta" "name")
    resident_mandate=$(ma_meta_get "$resident_meta" "mandate")
    [ -n "$resident_name" ] || resident_name="$resident_id"
    [ -n "$enabled" ] || enabled=0
    [ -n "$visible" ] || visible=0
    [ -n "$background" ] || background=0
    [ -n "$reserve_compute" ] || reserve_compute=0

    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0
    printf '{"id":"%s","name":"%s","mandate":"%s","enabled":%s,"visible":%s,"background":%s,"reserve_compute":%s,"model":"%s"}' \
      "$(json_escape "$resident_id")" \
      "$(json_escape "$resident_name")" \
      "$(json_escape "$resident_mandate")" \
      "$enabled" "$visible" "$background" "$reserve_compute" \
      "$(json_escape "$resident_model")"
  done
  printf ']'
}

ma_new_proposal() {
  workspace_id=$1
  conversation_id=$2
  resident_id=$3
  summary=$4
  target_type=$5
  escalation_class=$6
  rationale=$7
  impact_threshold=${8:-0}
  target=${9:-}

  ma_workspace_init "$workspace_id"
  ma_target_type_is_valid "$target_type" || target_type="Workspace"
  ma_escalation_class_is_valid "$escalation_class" || escalation_class="PolicyTradeoff"

  proposal_id=$(new_id)
  proposal_meta="$(ma_workspace_proposals_dir "$workspace_id")/$proposal_id.meta"
  created_epoch=$(date +%s 2>/dev/null || printf '0')
  cat > "$proposal_meta" <<EOF_META
id=$proposal_id
workspace_id=$workspace_id
conversation_id=$conversation_id
resident=$resident_id
summary=$summary
target=$target
target_type=$target_type
escalation_class=$escalation_class
rationale=$rationale
impact_threshold=$impact_threshold
status=pending
suppressed=0
decision=
created=$created_epoch
EOF_META
  printf '%s' "$proposal_id"
}

ma_policy_match_for_proposal() {
  proposal_meta=$1
  workspace_id=$2

  proposal_resident=$(ma_meta_get "$proposal_meta" "resident")
  proposal_target_type=$(ma_meta_get "$proposal_meta" "target_type")
  proposal_escalation=$(ma_meta_get "$proposal_meta" "escalation_class")
  proposal_impact=$(ma_meta_get "$proposal_meta" "impact_threshold")
  [ -n "$proposal_impact" ] || proposal_impact=0

  policy_match=0
  for policy_meta in "$(ma_global_policies_dir)"/*.meta "$(ma_workspace_policies_dir "$workspace_id")"/*.meta; do
    [ -f "$policy_meta" ] || continue
    policy_resident=$(ma_meta_get "$policy_meta" "resident")
    policy_target_type=$(ma_meta_get "$policy_meta" "target_type")
    policy_escalation=$(ma_meta_get "$policy_meta" "escalation_class")
    policy_impact=$(ma_meta_get "$policy_meta" "impact_threshold")

    if [ -n "$policy_resident" ] && [ "$policy_resident" != "$proposal_resident" ]; then
      continue
    fi
    if [ -n "$policy_target_type" ] && [ "$policy_target_type" != "$proposal_target_type" ]; then
      continue
    fi
    if [ -n "$policy_escalation" ] && [ "$policy_escalation" != "$proposal_escalation" ]; then
      continue
    fi
    if [ -n "$policy_impact" ]; then
      case "$policy_impact" in
        *[!0-9]*|'') policy_impact=0 ;;
      esac
      case "$proposal_impact" in
        *[!0-9]*|'') proposal_impact=0 ;;
      esac
      if [ "$proposal_impact" -lt "$policy_impact" ]; then
        continue
      fi
    fi
    policy_match=1
    break
  done

  printf '%s' "$policy_match"
}

ma_proposal_json() {
  proposal_meta=$1
  suppressed_effective=${2:-0}
  workspace_id=$(ma_meta_get "$proposal_meta" "workspace_id")
  conversation_id=$(ma_meta_get "$proposal_meta" "conversation_id")
  proposal_id=$(ma_meta_get "$proposal_meta" "id")
  proposal_summary=$(ma_meta_get "$proposal_meta" "summary")
  proposal_target=$(ma_meta_get "$proposal_meta" "target")
  proposal_target_type=$(ma_meta_get "$proposal_meta" "target_type")
  proposal_escalation=$(ma_meta_get "$proposal_meta" "escalation_class")
  proposal_rationale=$(ma_meta_get "$proposal_meta" "rationale")
  proposal_resident=$(ma_meta_get "$proposal_meta" "resident")
  proposal_status=$(ma_meta_get "$proposal_meta" "status")
  proposal_decision=$(ma_meta_get "$proposal_meta" "decision")
  proposal_impact=$(ma_meta_get "$proposal_meta" "impact_threshold")
  proposal_created=$(ma_meta_get "$proposal_meta" "created")

  [ -n "$proposal_status" ] || proposal_status="pending"
  [ -n "$proposal_impact" ] || proposal_impact=0
  [ -n "$proposal_created" ] || proposal_created=0

  printf '{"id":"%s","workspace_id":"%s","conversation_id":"%s","summary":"%s","target":"%s","target_type":"%s","escalation_class":"%s","rationale":"%s","resident":"%s","impact_threshold":%s,"status":"%s","decision":"%s","created":"%s","suppressed":%s}' \
    "$(json_escape "$proposal_id")" \
    "$(json_escape "$workspace_id")" \
    "$(json_escape "$conversation_id")" \
    "$(json_escape "$proposal_summary")" \
    "$(json_escape "$proposal_target")" \
    "$(json_escape "$proposal_target_type")" \
    "$(json_escape "$proposal_escalation")" \
    "$(json_escape "$proposal_rationale")" \
    "$(json_escape "$proposal_resident")" \
    "$proposal_impact" \
    "$(json_escape "$proposal_status")" \
    "$(json_escape "$proposal_decision")" \
    "$(json_escape "$proposal_created")" \
    "$suppressed_effective"
}

ma_triage_cards_json() {
  first=1
  printf '['
  for ws_dir in "$workspaces_dir"/*; do
    [ -d "$ws_dir" ] || continue
    workspace_id=$(basename "$ws_dir")
    ma_workspace_init "$workspace_id"
    proposals_dir=$(ma_workspace_proposals_dir "$workspace_id")
    for proposal_meta in "$proposals_dir"/*.meta; do
      [ -f "$proposal_meta" ] || continue
      proposal_status=$(ma_meta_get "$proposal_meta" "status")
      [ "$proposal_status" = "pending" ] || continue
      proposal_target_type=$(ma_meta_get "$proposal_meta" "target_type")
      # Charter amendments always surface
      suppressed=0
      if [ "$proposal_target_type" != "Charter" ]; then
        suppressed=$(ma_policy_match_for_proposal "$proposal_meta" "$workspace_id")
      fi
      if [ "$suppressed" = "1" ]; then
        continue
      fi
      if [ "$first" -eq 0 ]; then
        printf ','
      fi
      first=0
      ma_proposal_json "$proposal_meta" 0
    done
  done
  printf ']'
}

ma_workspace_unratified_amendments_json() {
  workspace_id=$1
  first=1
  printf '['
  proposals_dir=$(ma_workspace_proposals_dir "$workspace_id")
  for proposal_meta in "$proposals_dir"/*.meta; do
    [ -f "$proposal_meta" ] || continue
    target_type=$(ma_meta_get "$proposal_meta" "target_type")
    [ "$target_type" = "Charter" ] || continue
    status=$(ma_meta_get "$proposal_meta" "status")
    [ "$status" = "pending" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0
    ma_proposal_json "$proposal_meta" 0
  done
  printf ']'
}

ma_read_log_entries_json() {
  dir_path=$1
  first=1
  printf '['
  for entry_file in "$dir_path"/*.meta; do
    [ -f "$entry_file" ] || continue
    entry_id=$(basename "$entry_file" .meta)
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    first=0
    printf '{"id":"%s"' "$(json_escape "$entry_id")"
    while IFS='=' read -r key value; do
      [ -n "$key" ] || continue
      case "$key" in
        id) ;;
        impact_threshold)
          case "$value" in
            *[!0-9]*|'') value=0 ;;
          esac
          printf ',"%s":%s' "$(json_escape "$key")" "$value"
          ;;
        *)
          printf ',"%s":"%s"' "$(json_escape "$key")" "$(json_escape "$value")"
          ;;
      esac
    done < "$entry_file"
    printf '}'
  done
  printf ']'
}

ma_workspace_state_json() {
  workspace_id=$1
  ma_workspace_init "$workspace_id"
  toggles_file=$(ma_workspace_toggles_file "$workspace_id")
  charter_file=$(ma_workspace_charter_file "$workspace_id")
  meta_file=$(ma_workspace_meta_file "$workspace_id")

  dilemma=$(ma_toggle_value "$workspace_id" "dilemma_surfacing" 1)
  amendments=$(ma_toggle_value "$workspace_id" "amendments" 1)
  interpretation=$(ma_toggle_value "$workspace_id" "interpretation_log" 1)
  commitments=$(ma_toggle_value "$workspace_id" "commitments" 1)
  attention=$(ma_toggle_value "$workspace_id" "attention_policies" 1)
  charter_text=$(cat "$charter_file" 2>/dev/null || true)
  ontology_link=$(ma_meta_get "$meta_file" "ontology_link")
  shared_context_ids=$(ma_meta_get "$meta_file" "shared_context_workspace_ids")

  printf '{"workspace_id":"%s","charter":"%s","ontology_link":"%s","shared_context_workspace_ids":"%s","toggles":{"dilemma_surfacing":%s,"amendments":%s,"interpretation_log":%s,"commitments":%s,"attention_policies":%s},"residents":%s,"background_resident_count":%s,"unratified_amendments":%s,"interpretation_log":%s,"commitments_log":%s,"attention_policies":%s,"global_attention_policies":%s}' \
    "$(json_escape "$workspace_id")" \
    "$(json_escape "$charter_text")" \
    "$(json_escape "$ontology_link")" \
    "$(json_escape "$shared_context_ids")" \
    "$dilemma" "$amendments" "$interpretation" "$commitments" "$attention" \
    "$(ma_residents_json_for_workspace "$workspace_id")" \
    "$(ma_workspace_background_resident_count "$workspace_id")" \
    "$(ma_workspace_unratified_amendments_json "$workspace_id")" \
    "$(ma_read_log_entries_json "$(ma_workspace_interpretation_dir "$workspace_id")")" \
    "$(ma_read_log_entries_json "$(ma_workspace_commitments_dir "$workspace_id")")" \
    "$(ma_read_log_entries_json "$(ma_workspace_policies_dir "$workspace_id")")" \
    "$(ma_read_log_entries_json "$(ma_global_policies_dir)")"
}

ma_add_interpretation_entry() {
  workspace_id=$1
  entry_text=$2
  ma_workspace_init "$workspace_id"
  entry_id=$(new_id)
  entry_file="$(ma_workspace_interpretation_dir "$workspace_id")/$entry_id.meta"
  cat > "$entry_file" <<EOF_META
statement=$entry_text
created=$(date +%s 2>/dev/null || printf '0')
EOF_META
  printf '%s' "$entry_id"
}

ma_add_commitment_entry() {
  workspace_id=$1
  statement=$2
  scope=$3
  duration=$4
  revocability=$5
  audience=$6
  ma_workspace_init "$workspace_id"
  entry_id=$(new_id)
  entry_file="$(ma_workspace_commitments_dir "$workspace_id")/$entry_id.meta"
  cat > "$entry_file" <<EOF_META
statement=$statement
scope=$scope
duration=$duration
revocability=$revocability
audience=$audience
status=active
created=$(date +%s 2>/dev/null || printf '0')
EOF_META
  printf '%s' "$entry_id"
}

ma_update_commitment_status() {
  workspace_id=$1
  entry_id=$2
  next_status=$3
  case "$next_status" in
    active|fulfilled|revoked) ;;
    *) return 1 ;;
  esac
  ma_workspace_init "$workspace_id"
  entry_file="$(ma_workspace_commitments_dir "$workspace_id")/$entry_id.meta"
  [ -f "$entry_file" ] || return 1
  ma_meta_set "$entry_file" "status" "$next_status"
  ma_meta_set "$entry_file" "updated" "$(date +%s 2>/dev/null || printf '0')"
  return 0
}

ma_delete_workspace_log_entry() {
  workspace_id=$1
  log_kind=$2
  entry_id=$3
  case "$log_kind" in
    interpretation)
      target_file="$(ma_workspace_interpretation_dir "$workspace_id")/$entry_id.meta"
      ;;
    commitments)
      target_file="$(ma_workspace_commitments_dir "$workspace_id")/$entry_id.meta"
      ;;
    policies)
      target_file="$(ma_workspace_policies_dir "$workspace_id")/$entry_id.meta"
      ;;
    global-policies)
      target_file="$(ma_global_policies_dir)/$entry_id.meta"
      ;;
    *)
      return 1
      ;;
  esac
  [ -f "$target_file" ] || return 1
  rm -f "$target_file"
}

ma_create_policy_from_proposal() {
  proposal_meta=$1
  scope=$2
  workspace_id=$(ma_meta_get "$proposal_meta" "workspace_id")
  proposal_resident=$(ma_meta_get "$proposal_meta" "resident")
  proposal_target_type=$(ma_meta_get "$proposal_meta" "target_type")
  proposal_escalation=$(ma_meta_get "$proposal_meta" "escalation_class")
  proposal_impact=$(ma_meta_get "$proposal_meta" "impact_threshold")

  policy_id=$(new_id)
  case "$scope" in
    global)
      policy_file="$(ma_global_policies_dir)/$policy_id.meta"
      ;;
    *)
      policy_file="$(ma_workspace_policies_dir "$workspace_id")/$policy_id.meta"
      ;;
  esac
  cat > "$policy_file" <<EOF_META
scope=$scope
workspace_id=$workspace_id
resident=$proposal_resident
target_type=$proposal_target_type
escalation_class=$proposal_escalation
impact_threshold=$proposal_impact
created=$(date +%s 2>/dev/null || printf '0')
source=proposal
EOF_META
  printf '%s' "$policy_id"
}

ma_mark_proposal_decision() {
  proposal_meta=$1
  next_status=$2
  decision_text=$3
  ma_meta_set "$proposal_meta" "status" "$next_status"
  ma_meta_set "$proposal_meta" "decision" "$decision_text"
}

ma_find_proposal_meta() {
  proposal_id=$1
  for ws_dir in "$workspaces_dir"/*; do
    [ -d "$ws_dir" ] || continue
    workspace_id=$(basename "$ws_dir")
    proposal_meta="$(ma_workspace_proposals_dir "$workspace_id")/$proposal_id.meta"
    if [ -f "$proposal_meta" ]; then
      printf '%s' "$proposal_meta"
      return 0
    fi
  done
  printf '%s' ""
}

ma_cleanup_preview_json() {
  cleanup_directive=${1:-}
  cards_json=$(ma_triage_cards_json)
  printf '%s\n' "$cards_json" | INST_CLEANUP_DIRECTIVE="$cleanup_directive" perl -MJSON::PP -e '
    use strict; use warnings;
    local $/; my $raw=<STDIN>;
    my $cards = eval { decode_json($raw) };
    if ($@ || ref($cards) ne "ARRAY") { print "{\"collapsed\":[],\"before\":0,\"after\":0}"; exit 0; }
    my %groups;
    for my $c (@$cards) {
      next if ref($c) ne "HASH";
      my $key = join("|", map { ($c->{$_}//"") } qw(escalation_class target_type resident));
      push @{ $groups{$key} }, $c;
    }
    my @collapsed;
    for my $key (sort keys %groups) {
      my $items = $groups{$key} || [];
      next if !@$items;
      my $first = $items->[0];
      my %item = (
        summary => ($first->{summary} // "Decision cluster"),
        escalation_class => ($first->{escalation_class} // ""),
        target_type => ($first->{target_type} // ""),
        resident => ($first->{resident} // ""),
        count => scalar(@$items),
        proposal_ids => [ map { $_->{id} } @$items ]
      );
      push @collapsed, \%item;
    }
    my $out = {
      before => scalar(@$cards),
      after => scalar(@collapsed),
      collapsed => \@collapsed,
      directive => $ENV{INST_CLEANUP_DIRECTIVE} || ""
    };
    print encode_json($out);
  '
}
