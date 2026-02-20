(function () {
  "use strict";

  if (typeof window !== "undefined") {
    window.__artificerBooted = "loading";
  }

  var seenConversationStorageKey = "artificer.conversationSeenUpdated";
  var workspaceStateCacheKey = "artificer.workspaceStateCache.v1";
  var runEventsStorageKey = "artificer.runEventsByConversation.v1";

  function storageGet(key, fallback) {
    try {
      var value = window.localStorage.getItem(key);
      if (value === null || typeof value === "undefined") {
        return fallback;
      }
      return value;
    } catch (_err) {
      return fallback;
    }
  }

  function storageSet(key, value) {
    try {
      window.localStorage.setItem(key, value);
      return true;
    } catch (_err) {
      return false;
    }
  }

  function parseSeenUpdatedValue(value) {
    var parsed = Number(value);
    if (!isFinite(parsed) || parsed < 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  function loadSeenConversationState() {
    var raw = "";
    try {
      raw = window.localStorage.getItem(seenConversationStorageKey) || "";
    } catch (_err) {
      return { map: {}, hasSaved: false };
    }

    if (!raw) {
      return { map: {}, hasSaved: false };
    }

    var parsed = null;
    try {
      parsed = JSON.parse(raw);
    } catch (_err2) {
      return { map: {}, hasSaved: true };
    }

    if (!parsed || typeof parsed !== "object") {
      return { map: {}, hasSaved: true };
    }

    var clean = {};
    var keys = Object.keys(parsed);
    for (var i = 0; i < keys.length; i += 1) {
      var key = keys[i];
      clean[key] = parseSeenUpdatedValue(parsed[key]);
    }

    return { map: clean, hasSaved: true };
  }

  function clipTextForStorage(value, maxChars) {
    var text = String(value || "");
    var limit = Number(maxChars || 0);
    if (!isFinite(limit) || limit < 1) {
      return "";
    }
    if (text.length <= limit) {
      return text;
    }
    if (limit <= 16) {
      return text.slice(0, limit);
    }
    return text.slice(0, limit - 16) + " [truncated]";
  }

  function normalizeRunChecklistStatus(value) {
    var status = String(value || "").toLowerCase();
    if (status === "completed" || status === "complete" || status === "finished") {
      return "done";
    }
    if (status === "in-progress" || status === "in_progress" || status === "working") {
      return "active";
    }
    if (status === "todo" || status === "open" || status === "queued") {
      return "pending";
    }
    if (status !== "done" && status !== "active" && status !== "pending") {
      return "pending";
    }
    return status;
  }

  function normalizeRunTaskStatusSnapshot(snapshot) {
    if (!snapshot || typeof snapshot !== "object") {
      return null;
    }
    var source = String(snapshot.source || "backend");
    var inputTasks = Array.isArray(snapshot.tasks) ? snapshot.tasks : [];
    var tasks = [];
    var completed = 0;
    for (var i = 0; i < inputTasks.length && tasks.length < 40; i += 1) {
      var item = inputTasks[i] || {};
      var id = clipTextForStorage(item.id || "", 160);
      var text = clipTextForStorage(item.text || item.title || item.label || "", 520);
      if (!text) {
        continue;
      }
      var status = normalizeRunChecklistStatus(item.status || "");
      var done = status === "done" || item.done === true;
      if (done) {
        status = "done";
        completed += 1;
      }
      tasks.push({
        id: id,
        text: text,
        status: status,
        done: done
      });
    }
    if (!tasks.length) {
      return null;
    }
    return {
      tasks: tasks,
      completed: completed,
      total: tasks.length,
      source: clipTextForStorage(source, 64) || "backend"
    };
  }

  function sanitizeRunEventForStorage(event) {
    if (!event || typeof event !== "object") {
      return null;
    }
    var status = String(event.status || "done");
    if (
      status !== "running" &&
      status !== "done" &&
      status !== "error" &&
      status !== "cancelled" &&
      status !== "awaiting_approval" &&
      status !== "awaiting_decision" &&
      status !== "approval_granted"
    ) {
      status = "done";
    }
    var cleaned = {
      id: clipTextForStorage(event.id || "", 120),
      status: status,
      started_at: clipTextForStorage(event.started_at || "", 80),
      finished_at: clipTextForStorage(event.finished_at || "", 80),
      model: clipTextForStorage(event.model || "", 200),
      error: clipTextForStorage(event.error || "", 2400),
      decision_hint: clipTextForStorage(event.decision_hint || "", 1400),
      stream_text: clipTextForStorage(event.stream_text || "", 7000),
      plan: clipTextForStorage(event.plan || "", 5000),
      git_status: clipTextForStorage(event.git_status || "", 5000),
      git_diff: clipTextForStorage(event.git_diff || "", 7000),
      state: clipTextForStorage(event.state || "", 4000),
      failures: clipTextForStorage(event.failures || "", 7000),
      session_log: clipTextForStorage(event.session_log || "", 7000)
    };
    var taskStatus = normalizeRunTaskStatusSnapshot(event.task_status);
    if (taskStatus && taskStatus.total > 0) {
      cleaned.task_status = taskStatus;
    }
    var commands = Array.isArray(event.commands) ? event.commands : [];
    if (commands.length) {
      cleaned.commands = [];
      for (var i = 0; i < commands.length && cleaned.commands.length < 12; i += 1) {
        var item = commands[i] || {};
        cleaned.commands.push({
          command: clipTextForStorage(item.command || "", 800),
          status: clipTextForStorage(item.status || "", 40),
          output: clipTextForStorage(item.output || "", 1800)
        });
      }
    } else {
      cleaned.commands = [];
    }
    if (!cleaned.id) {
      cleaned.id = String(Date.now()) + "-" + String(Math.floor(Math.random() * 999999));
    }
    return cleaned;
  }

  function compactRunEventsForStorage(source) {
    var map = source && typeof source === "object" ? source : {};
    var result = {};
    var keys = Object.keys(map);
    for (var i = 0; i < keys.length; i += 1) {
      var conversationId = String(keys[i] || "");
      if (!conversationId) {
        continue;
      }
      var list = Array.isArray(map[conversationId]) ? map[conversationId] : [];
      if (!list.length) {
        continue;
      }
      var start = Math.max(0, list.length - 12);
      var cleanedList = [];
      for (var j = start; j < list.length; j += 1) {
        var sanitized = sanitizeRunEventForStorage(list[j]);
        if (sanitized) {
          cleanedList.push(sanitized);
        }
      }
      if (cleanedList.length) {
        result[conversationId] = cleanedList;
      }
    }
    return result;
  }

  function loadRunEventsState() {
    var raw = "";
    try {
      raw = window.localStorage.getItem(runEventsStorageKey) || "";
    } catch (_err) {
      return {};
    }
    if (!raw) {
      return {};
    }
    var parsed = null;
    try {
      parsed = JSON.parse(raw);
    } catch (_err2) {
      return {};
    }
    return compactRunEventsForStorage(parsed);
  }

  function saveRunEventsState(eventsMap) {
    try {
      var compacted = compactRunEventsForStorage(eventsMap);
      window.localStorage.setItem(runEventsStorageKey, JSON.stringify(compacted));
    } catch (_err) {
      return;
    }
  }

  function parseStoredPaneWidth(key, fallback) {
    var raw = Number(storageGet(key, String(fallback)));
    if (!isFinite(raw) || raw <= 0) {
      return fallback;
    }
    return Math.round(raw);
  }

  function loadWorkspaceStateCache() {
    var raw = "";
    try {
      raw = window.localStorage.getItem(workspaceStateCacheKey) || "";
    } catch (_err) {
      return null;
    }
    if (!raw) {
      return null;
    }
    var parsed = null;
    try {
      parsed = JSON.parse(raw);
    } catch (_err2) {
      return null;
    }
    if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.workspaces)) {
      return null;
    }
    var savedAt = Number(parsed.saved_at || 0);
    if (!isFinite(savedAt) || savedAt <= 0) {
      return null;
    }
    if (Date.now() - savedAt > 1000 * 60 * 60 * 24) {
      return null;
    }
    return parsed;
  }

  function saveWorkspaceStateCache(workspaces) {
    if (!Array.isArray(workspaces)) {
      return;
    }
    try {
      window.localStorage.setItem(workspaceStateCacheKey, JSON.stringify({
        saved_at: Date.now(),
        workspaces: workspaces
      }));
    } catch (_err) {
      return;
    }
  }

  function slugifyRoutePart(text) {
    var value = String(text || "").toLowerCase();
    value = value.replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    return value;
  }

  function encodeRoutePart(text) {
    return encodeURIComponent(String(text || ""));
  }

  function decodeRoutePart(text) {
    try {
      return decodeURIComponent(String(text || ""));
    } catch (_err) {
      return String(text || "");
    }
  }

  function normalizeRoutePath(pathname) {
    var raw = String(pathname || "/");
    if (!raw) {
      raw = "/";
    }
    if (raw.charAt(0) !== "/") {
      raw = "/" + raw;
    }
    return raw.replace(/\/{2,}/g, "/");
  }

  function routeTokenFromLabelAndId(label, id) {
    var idText = String(id || "");
    var slug = slugifyRoutePart(label || idText);
    if (slug && idText) {
      return slug + "--" + idText;
    }
    return slug || idText;
  }

  function routeIdHint(token) {
    var raw = String(token || "");
    var marker = raw.lastIndexOf("--");
    if (marker > 0 && marker + 2 < raw.length) {
      return raw.slice(marker + 2);
    }
    return raw;
  }

  function parseRouteSelectionFromLocation() {
    if (typeof window === "undefined" || !window.location) {
      return null;
    }
    var path = normalizeRoutePath(window.location.pathname || "/");
    var segments = path.split("/").filter(function (part) {
      return !!part;
    });
    if (segments.length >= 2 && segments[0] === "pages" && /^index\.html?$/i.test(segments[1])) {
      segments = segments.slice(2);
    }
    if (!segments.length) {
      return null;
    }
    var workspaceToken = decodeRoutePart(segments[0]);
    var conversationToken = segments.length > 1 ? decodeRoutePart(segments[1]) : "";
    if (!workspaceToken) {
      return null;
    }
    return {
      workspaceToken: workspaceToken,
      conversationToken: conversationToken
    };
  }

  var initialSeenConversationState = loadSeenConversationState();
  var initialRunEventsState = loadRunEventsState();

  var state = {
    models: [],
    workspaces: [],
    activeWorkspaceId: "",
    activeConversationId: "",
    activeConversation: null,
    activeDraftWorkspaceId: "",
    draftTextByWorkspace: {},
    draftModelByWorkspace: {},
    runEventsByConversation: initialRunEventsState,
    expandedWorkspaceIds: {},
    busy: false,
    pickingWorkspace: false,
    sortMode: storageGet("artificer.workspaceSort", "updated"),
    organizeMode: storageGet("artificer.organizeMode", "project"),
    organizeShow: storageGet("artificer.organizeShow", "all"),
    permissionMode: storageGet("artificer.permissionMode", "default"),
    commandExecMode: storageGet("artificer.commandExecMode", "ask-some"),
    githubUsername: storageGet("artificer.githubUsername", ""),
    networkAccess: storageGet("artificer.networkAccess", "0") === "1",
    webAccess: storageGet("artificer.webAccess", "0") === "1",
    agentLoopEnabled: storageGet("artificer.agentLoopEnabled", "1") !== "0",
    runMode: storageGet("artificer.runMode", "auto"),
    assistantModeId: storageGet("artificer.assistantModeId", ""),
    runModeMoreExpanded: false,
    reasoningEffort: storageGet("artificer.reasoningEffort", "medium"),
    computeBudget: storageGet("artificer.computeBudget", "auto"),
    gitByWorkspace: {},
    branchesByWorkspace: {},
    diffOpen: false,
    diffText: "",
    terminalOpen: false,
    terminalBusy: false,
    terminalLines: [],
    terminalSessionId: "",
    terminalSessionWorkspaceId: "",
    terminalStreamText: "",
    terminalStreamOffset: 0,
    terminalCwd: "",
    terminalInputBuffer: "",
    openMenus: {},
    commitModalDefault: "commit",
    lastOpenTarget: storageGet("artificer.lastOpenTarget", "finder"),
    lastCommitAction: storageGet("artificer.lastCommitAction", "commit"),
    activeTheme: storageGet("artificer.activeTheme", "psionic"),
    themes: [],
    queueWorkerActive: false,
    queueItemsByConversation: {},
    queueItemsLoadingByConversation: {},
    queueItemsFetchedAtByConversation: {},
    queueEdit: {
      workspaceId: "",
      conversationId: "",
      itemId: "",
      draftText: "",
      saving: false
    },
    runningWorkspaceId: "",
    runningConversationId: "",
    awaitingApprovalByConversation: {},
    lastQueuedItemIdByConversation: {},
    decisionInlineDismissedKey: "",
    seenConversationUpdatedByKey: initialSeenConversationState.map,
    seenConversationBootstrapPending: !initialSeenConversationState.hasSaved,
    openWorkspaceMenuWorkspaceId: "",
    workspaceTreeMarkupCache: "",
    pendingArchiveKey: "",
    pendingArchiveReadyAt: 0,
    pendingArchiveSubmittingKey: "",
    pendingAttachments: [],
    composerDragDepth: 0,
    awaitingDirPicker: false,
    modelLoadError: "",
    appIcons: {
      finder: "",
      textmate: ""
    },
    modelCatalog: [],
    modelInstalls: [],
    modelInstallJob: null,
    modelInstallLog: "",
    commandRulesByWorkspace: {},
    commandRulesWorkspaceId: "",
    commandRulesLastRenderedWorkspaceId: "",
    commandRulesLoading: false,
    commandRulesError: "",
    modeRuntime: {
      scheduler: {},
      modes: [],
      skills: [],
      panels: []
    },
    triage: {
      count: "0",
      cards: []
    },
    multi_agentCatalog: {
      curated_residents: [],
      target_types: [],
      escalation_classes: []
    },
    workspaceMultiAgentById: {},
    workspaceMultiAgentLoadingById: {},
    workspaceMultiAgentErrorById: {},
    multiAgentSelectedResidentIdByWorkspace: {},
    multiAgentOpenResidentOptionsByWorkspace: {},
    multiAgentCharterAutosaveTimerByWorkspace: {},
    openTriageSuppressProposalId: "",
    activeTriage: false,
    modeRuntimeLoading: false,
    modeRuntimeError: "",
    contextWindowText: "Context window information will display here.",
    lastErrorText: "",
    lastErrorAt: 0,
    initialLoadComplete: false,
    selectionVersion: 0,
    chatAutoScroll: true,
    chatLastKey: "",
    chatMarkupCache: "",
    runDetailsOpenByEventId: {},
    runStreamAutoFollowByEventId: {},
    runStreamScrollTopByEventId: {},
    runTodoMonitorOpenByConversation: {},
    runTerminalMonitorOpenByConversation: {},
    pendingOutgoingByKey: {},
    conversationCacheByKey: {},
    threadsPaneWidth: parseStoredPaneWidth("artificer.threadsPaneWidth", 308),
    diffPaneWidth: 300,
    modelsPaneHeight: parseStoredPaneWidth("artificer.modelsPaneHeight", 300),
    pendingRouteSelection: parseRouteSelectionFromLocation(),
    suppressSelectionUrlSync: false
  };

  var saveDraftTimer = null;
  var liveRunTickTimer = null;
  var runStreamPollTimers = {};
  var modelInstallPollTimer = null;
  var modelAutoRefreshTimer = null;
  var modelAutoRefreshBusy = false;
  var modelAutoRefreshLastAt = 0;
  var runReconcileTimer = null;
  var runReconcileBusy = false;
  var runEventsSaveTimer = null;
  var runEventHealTimer = null;
  var runEventHealBusy = false;
  var runEventHealBusySince = 0;
  var runEventHealGuardTimer = null;
  var terminalStateWatchTimer = null;
  var terminalStateWatchBusy = false;
  var approvalResumeWatchTimer = null;
  var approvalResumeWatchBusy = false;
  var approvalResumeWatchKey = "";
  var approvalResumeWatchDeadline = 0;
  var terminalPollTimer = null;
  var terminalPollBusy = false;
  var terminalSessionStartPromise = null;
  var paneDragState = null;
  var suppressMenuCloseUntilMs = 0;
  var pathWidgetClickTimer = null;
  var tooltipEl = null;
  var tooltipTarget = null;
  var tooltipShowTimer = null;
  var tooltipPendingTarget = null;
  var noticeEl = null;
  var noticeHideTimer = null;
  var pendingCommandApproval = null;
  var approvalAnswerPending = false;
  var TOOLTIP_DELAY_MS = 520;

  if (state.sortMode !== "updated" && state.sortMode !== "created") {
    state.sortMode = "updated";
  }
  if (state.organizeMode !== "project" && state.organizeMode !== "chrono") {
    state.organizeMode = "project";
  }
  if (state.organizeShow !== "all" && state.organizeShow !== "relevant" && state.organizeShow !== "running") {
    state.organizeShow = "all";
  }
  if (state.lastOpenTarget !== "finder" && state.lastOpenTarget !== "terminal" && state.lastOpenTarget !== "textmate") {
    state.lastOpenTarget = "finder";
  }
  if (state.lastCommitAction !== "commit" && state.lastCommitAction !== "push" && state.lastCommitAction !== "commit-push") {
    state.lastCommitAction = "commit";
  }
  if (
    state.reasoningEffort !== "low" &&
    state.reasoningEffort !== "medium" &&
    state.reasoningEffort !== "high" &&
    state.reasoningEffort !== "extra-high"
  ) {
    state.reasoningEffort = "medium";
  }
  if (
    state.computeBudget !== "auto" &&
    state.computeBudget !== "quick" &&
    state.computeBudget !== "standard" &&
    state.computeBudget !== "long" &&
    state.computeBudget !== "until-complete"
  ) {
    state.computeBudget = "auto";
  }
  if (!/^[a-z0-9_-]+$/.test(String(state.activeTheme || ""))) {
    state.activeTheme = "psionic";
  }
  if (
    state.commandExecMode !== "none" &&
    state.commandExecMode !== "ask" &&
    state.commandExecMode !== "ask-all" &&
    state.commandExecMode !== "ask-some" &&
    state.commandExecMode !== "all"
  ) {
    state.commandExecMode = "ask-some";
  }
  if (state.commandExecMode === "ask") {
    state.commandExecMode = "ask-some";
  }
  state.runMode = normalizeRunMode(state.runMode);
  state.assistantModeId = normalizeAssistantModeId(state.assistantModeId);
  if (state.runMode === "instant") {
    state.agentLoopEnabled = false;
    state.reasoningEffort = "low";
  } else if (state.runMode === "chat") {
    state.agentLoopEnabled = false;
    if (state.reasoningEffort === "low") {
      state.reasoningEffort = "medium";
    }
  } else if (state.runMode === "programming") {
    state.agentLoopEnabled = true;
    if (state.reasoningEffort === "low" || state.reasoningEffort === "medium") {
      state.reasoningEffort = "high";
    }
  } else if (state.runMode === "report") {
    state.agentLoopEnabled = true;
    if (state.reasoningEffort === "low" || state.reasoningEffort === "medium") {
      state.reasoningEffort = "high";
    }
  } else if (state.runMode === "assistant") {
    state.agentLoopEnabled = true;
    state.reasoningEffort = "extra-high";
  }

  var el = {
    shell: document.getElementById("forge-shell"),
    toolbar: document.querySelector(".toolbar"),
    workspacePanel: document.getElementById("workspace-dropzone"),
    threadsResizer: document.getElementById("threads-resizer"),
    workspaceTree: document.getElementById("workspace-tree"),
    addWorkspaceBtn: document.getElementById("add-workspace-btn"),
    organizeBtn: document.getElementById("organize-btn"),
    organizeMenu: document.getElementById("organize-menu"),
    modelStatusBtn: document.getElementById("model-status-btn"),
    settingsBtn: document.getElementById("settings-btn"),
    themePickerBtn: document.getElementById("theme-picker-btn"),
    themePickerMenu: document.getElementById("theme-picker-menu"),
    themePickerList: document.getElementById("theme-picker-list"),
    themeStylesheet: document.getElementById("artificer-theme-stylesheet"),
    modelsPane: document.getElementById("models-pane"),
    modelsPaneResizer: document.getElementById("models-pane-resizer"),
    modelsBox: document.getElementById("models-box"),
    modelsBoxList: document.getElementById("models-box-list"),

    openMainBtn: document.getElementById("open-main-btn"),
    openMenuBtn: document.getElementById("open-menu-btn"),
    openMenu: document.getElementById("open-menu"),
    commitMainBtn: document.getElementById("commit-main-btn"),
    commitMenuBtn: document.getElementById("commit-menu-btn"),
    commitMenu: document.getElementById("commit-menu"),
    branchMenuBtn: document.getElementById("branch-menu-btn"),
    branchMenu: document.getElementById("branch-menu"),
    branchMenuList: document.getElementById("branch-menu-list"),
    branchCreateForm: document.getElementById("branch-create-form"),
    branchCreateInput: document.getElementById("branch-create-input"),
    branchCreateSubmit: document.getElementById("branch-create-submit"),
    runActionBtn: document.getElementById("run-action-btn"),
    permissionsMenuBtn: document.getElementById("permissions-menu-btn"),
    permissionsMenu: document.getElementById("permissions-menu"),
    networkToggleBtn: document.getElementById("network-toggle-btn"),
    webToggleBtn: document.getElementById("web-toggle-btn"),
    terminalToggleBtn: document.getElementById("terminal-toggle-btn"),
    changesBtn: document.getElementById("changes-btn"),
    contextWindowBtn: document.getElementById("context-window-btn"),
    contextWindowMenu: document.getElementById("context-window-menu"),
    contextWindowBody: document.getElementById("context-window-body"),
    workspacePathWidget: document.getElementById("workspace-path-widget"),

    chatTitle: document.getElementById("chat-title"),
    chatLog: document.getElementById("chat-log"),
    chatJumpBottomBtn: document.getElementById("chat-jump-bottom-btn"),
    runForm: document.getElementById("run-form"),
    runPrompt: document.getElementById("run-prompt"),
    attachBtn: document.getElementById("attach-btn"),
    attachmentPicker: document.getElementById("attachment-picker"),
    attachmentStrip: document.getElementById("attachment-strip"),
    modelPickerBtn: document.getElementById("model-picker-btn"),
    modelPickerMenu: document.getElementById("model-picker-menu"),
    modelPickerList: document.getElementById("model-picker-list"),
    runModeBtn: document.getElementById("run-mode-btn"),
    runModeMenu: document.getElementById("run-mode-menu"),
    runModeMoreToggle: document.getElementById("run-mode-more-toggle"),
    runModeMoreList: document.getElementById("run-mode-more-list"),
    agentLoopToggle: document.getElementById("agent-loop-toggle"),
    reasoningMenuBtn: document.getElementById("reasoning-menu-btn"),
    reasoningMenu: document.getElementById("reasoning-menu"),
    computeMenuBtn: document.getElementById("compute-menu-btn"),
    computeMenu: document.getElementById("compute-menu"),
    runTodoMonitor: document.getElementById("run-todo-monitor"),
    runTodoMonitorLabel: document.getElementById("run-todo-monitor-label"),
    runTodoMonitorList: document.getElementById("run-todo-monitor-list"),
    queueTray: document.getElementById("queue-tray"),
    queueTrayList: document.getElementById("queue-tray-list"),
    runTerminalMonitor: document.getElementById("run-terminal-monitor"),
    runTerminalMonitorLabel: document.getElementById("run-terminal-monitor-label"),
    runTerminalMonitorOutput: document.getElementById("run-terminal-monitor-output"),
    runTerminalMonitorStop: document.getElementById("run-terminal-monitor-stop"),
    queueControls: document.getElementById("queue-controls"),
    queueSteerBtn: document.getElementById("queue-steer-btn"),
    queueCancelBtn: document.getElementById("queue-cancel-btn"),
    runBtn: document.getElementById("run-btn"),

    diffPanel: document.getElementById("diff-panel"),
    diffResizer: document.getElementById("diff-resizer"),
    diffSummary: document.getElementById("diff-summary"),
    diffView: document.getElementById("diff-view"),
    diffCloseBtn: document.getElementById("diff-close-btn"),

    terminalPanel: document.getElementById("terminal-panel"),
    terminalCwd: document.getElementById("terminal-cwd"),
    terminalOutput: document.getElementById("terminal-output"),
    terminalForm: document.getElementById("terminal-form"),
    terminalInput: document.getElementById("terminal-input"),
    terminalClearBtn: document.getElementById("terminal-clear-btn"),
    terminalCloseBtn: document.getElementById("terminal-close-btn"),

    workspaceModal: document.getElementById("workspace-modal"),
    workspaceModalClose: document.getElementById("workspace-modal-close"),
    workspaceCancelBtn: document.getElementById("workspace-cancel-btn"),
    workspaceForm: document.getElementById("workspace-form"),
    workspacePath: document.getElementById("workspace-path"),
    workspaceName: document.getElementById("workspace-name"),
    workspaceBrowseBtn: document.getElementById("workspace-browse-btn"),
    workspaceDirPicker: document.getElementById("workspace-dir-picker"),

    commitModal: document.getElementById("commit-modal"),
    commitModalClose: document.getElementById("commit-modal-close"),
    commitBranchLabel: document.getElementById("commit-branch-label"),
    commitChangesLabel: document.getElementById("commit-changes-label"),
    commitIncludeUnstaged: document.getElementById("commit-include-unstaged"),
    commitMessage: document.getElementById("commit-message"),
    commitNextStep: document.getElementById("commit-next-step"),
    commitContinueBtn: document.getElementById("commit-continue-btn"),
    commandApprovalModal: document.getElementById("command-approval-modal"),
    commandApprovalClose: document.getElementById("command-approval-close"),
    commandApprovalText: document.getElementById("command-approval-text"),
    commandApprovalCommand: document.getElementById("command-approval-command"),
    commandApprovalMatchMode: document.getElementById("command-approval-match-mode"),
    commandApprovalPattern: document.getElementById("command-approval-pattern"),
    commandApprovalAllowOnce: document.getElementById("command-approval-allow-once"),
    commandApprovalDenyOnce: document.getElementById("command-approval-deny-once"),
    commandApprovalAllowRemember: document.getElementById("command-approval-allow-remember"),
    commandApprovalDenyRemember: document.getElementById("command-approval-deny-remember"),
    commandApprovalInline: document.getElementById("command-approval-inline"),
    commandApprovalInlineClose: document.getElementById("command-approval-inline-close"),
    commandApprovalInlineText: document.getElementById("command-approval-inline-text"),
    commandApprovalInlineCommand: document.getElementById("command-approval-inline-command"),
    commandApprovalInlineMatchMode: document.getElementById("command-approval-inline-match-mode"),
    commandApprovalInlinePattern: document.getElementById("command-approval-inline-pattern"),
    commandApprovalInlineAllowOnce: document.getElementById("command-approval-inline-allow-once"),
    commandApprovalInlineDenyOnce: document.getElementById("command-approval-inline-deny-once"),
    commandApprovalInlineAllowRemember: document.getElementById("command-approval-inline-allow-remember"),
    commandApprovalInlineDenyRemember: document.getElementById("command-approval-inline-deny-remember"),
    decisionRequestInline: document.getElementById("decision-request-inline"),
    decisionRequestInlineClose: document.getElementById("decision-request-inline-close"),
    decisionRequestInlineQuestion: document.getElementById("decision-request-inline-question"),
    decisionRequestForm: document.getElementById("decision-request-form"),
    decisionRequestOptions: document.getElementById("decision-request-options"),
    decisionRequestOtherWrap: document.getElementById("decision-request-other-wrap"),
    decisionRequestOtherInput: document.getElementById("decision-request-other-input"),
    decisionRequestSubmit: document.getElementById("decision-request-submit"),

    runActionModal: document.getElementById("run-action-modal"),
    runActionClose: document.getElementById("run-action-close"),
    runActionForm: document.getElementById("run-action-form"),
    runActionCommand: document.getElementById("run-action-command"),

    settingsModal: document.getElementById("settings-modal"),
    settingsCloseBtn: document.getElementById("settings-close-btn"),
    ghAuthStatus: document.getElementById("gh-auth-status"),
    sshKeyStatus: document.getElementById("ssh-key-status"),
    githubUsername: document.getElementById("github-username"),
    sshEmail: document.getElementById("ssh-email"),
    refreshAuthBtn: document.getElementById("refresh-auth-btn"),
    generateSshBtn: document.getElementById("generate-ssh-btn"),
    chooseSshBtn: document.getElementById("choose-ssh-btn"),
    clearSshBtn: document.getElementById("clear-ssh-btn"),
    selectedSshPath: document.getElementById("selected-ssh-path"),
    sshPubOutput: document.getElementById("ssh-pub-output"),
    commandRulesWorkspace: document.getElementById("command-rules-workspace"),
    commandRulesStatus: document.getElementById("command-rules-status"),
    commandRulesGlobalList: document.getElementById("command-rules-global-list"),
    commandRulesList: document.getElementById("command-rules-list"),
    modeRuntimeTickBtn: document.getElementById("mode-runtime-tick-btn"),
    modeRuntimeSummary: document.getElementById("mode-runtime-summary"),
    modeRuntimePanels: document.getElementById("mode-runtime-panels"),
    modeRuntimeModes: document.getElementById("mode-runtime-modes"),
    modeRuntimeSkills: document.getElementById("mode-runtime-skills"),
    assistantModeSelect: document.getElementById("assistant-mode-select"),
    assistantModeApplyBtn: document.getElementById("assistant-mode-apply-btn"),
    modeRuntimeSkillInvokeForm: document.getElementById("mode-runtime-skill-invoke-form"),
    modeRuntimeSkillSelect: document.getElementById("mode-runtime-skill-select"),
    modeRuntimeSkillMode: document.getElementById("mode-runtime-skill-mode"),
    modeRuntimeSkillCapabilities: document.getElementById("mode-runtime-skill-capabilities"),
    modeRuntimeSkillInput: document.getElementById("mode-runtime-skill-input"),
    modeRuntimeSkillInvokeBtn: document.getElementById("mode-runtime-skill-invoke-btn"),
    modeRuntimeSkillResult: document.getElementById("mode-runtime-skill-result"),
    modeRuntimeSkillCreateForm: document.getElementById("mode-runtime-skill-create-form"),
    modeRuntimeSkillCreateId: document.getElementById("mode-runtime-skill-create-id"),
    modeRuntimeSkillCreateName: document.getElementById("mode-runtime-skill-create-name"),
    modeRuntimeSkillCreateTrigger: document.getElementById("mode-runtime-skill-create-trigger"),
    modeRuntimeSkillCreateCapabilities: document.getElementById("mode-runtime-skill-create-capabilities"),
    modeRuntimeSkillCreateDescription: document.getElementById("mode-runtime-skill-create-description"),
    modeRuntimeSkillCreateBtn: document.getElementById("mode-runtime-skill-create-btn"),
    modeRuntimeSkillInstallForm: document.getElementById("mode-runtime-skill-install-form"),
    modeRuntimeSkillInstallSource: document.getElementById("mode-runtime-skill-install-source"),
    modeRuntimeSkillInstallId: document.getElementById("mode-runtime-skill-install-id"),
    modeRuntimeSkillInstallReplace: document.getElementById("mode-runtime-skill-install-replace"),
    modeRuntimeSkillInstallBtn: document.getElementById("mode-runtime-skill-install-btn"),
    multi_agentModal: document.getElementById("multi_agent-modal"),
    multi_agentModalClose: document.getElementById("multi_agent-modal-close"),
    multi_agentProjectLabel: document.getElementById("multi_agent-project-label"),
    multi_agentStatus: document.getElementById("multi_agent-status"),
    multi_agentCharter: document.getElementById("multi_agent-charter"),
    multi_agentRolesHint: document.getElementById("multi_agent-roles-hint"),
    multi_agentSectionDilemma: document.getElementById("multi_agent-section-dilemma"),
    multi_agentSectionAmendments: document.getElementById("multi_agent-section-amendments"),
    multi_agentSectionCommitments: document.getElementById("multi_agent-section-commitments"),
    multi_agentSectionPolicies: document.getElementById("multi_agent-section-policies"),
    multi_agentToggleAmendments: document.getElementById("multi_agent-toggle-amendments"),
    multi_agentToggleCommitments: document.getElementById("multi_agent-toggle-commitments"),
    multi_agentTogglePolicies: document.getElementById("multi_agent-toggle-policies"),
    multi_agentAmendmentsSummary: document.getElementById("multi_agent-amendments-summary"),
    multi_agentInterpretationSummary: document.getElementById("multi_agent-interpretation-summary"),
    multi_agentCommitmentsSummary: document.getElementById("multi_agent-commitments-summary"),
    multi_agentPoliciesSummary: document.getElementById("multi_agent-policies-summary"),
    multi_agentAmendmentsList: document.getElementById("multi_agent-amendments-list"),
    multi_agentResidentsList: document.getElementById("multi_agent-residents-list"),
    multi_agentPoliciesList: document.getElementById("multi_agent-policies-list"),
    multi_agentCommitmentsList: document.getElementById("multi_agent-commitments-list"),
    multi_agentInterpretationList: document.getElementById("multi_agent-interpretation-list")
  };

  if (el.modelStatusBtn) {
    el.modelStatusBtn.textContent = "Loading...";
  }
  if (el.githubUsername) {
    el.githubUsername.value = state.githubUsername || "";
  }

  var menuById = {
    "organize-menu": el.organizeMenu,
    "open-menu": el.openMenu,
    "commit-menu": el.commitMenu,
    "theme-picker-menu": el.themePickerMenu,
    "branch-menu": el.branchMenu,
    "permissions-menu": el.permissionsMenu,
    "model-picker-menu": el.modelPickerMenu,
    "run-mode-menu": el.runModeMenu,
    "reasoning-menu": el.reasoningMenu,
    "compute-menu": el.computeMenu,
    "context-window-menu": el.contextWindowMenu,
    "models-pane": el.modelsPane
  };

  function escHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function escAttr(text) {
    return escHtml(text)
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function trim(text) {
    return String(text || "").replace(/^\s+|\s+$/g, "");
  }

  function copyTextToClipboard(text) {
    var value = String(text || "");
    if (!value) {
      return Promise.resolve(false);
    }
    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(value).then(function () {
        return true;
      }).catch(function () {
        return false;
      });
    }
    try {
      var temp = document.createElement("textarea");
      temp.value = value;
      temp.setAttribute("readonly", "readonly");
      temp.style.position = "absolute";
      temp.style.left = "-9999px";
      document.body.appendChild(temp);
      temp.select();
      var ok = document.execCommand("copy");
      document.body.removeChild(temp);
      return Promise.resolve(!!ok);
    } catch (_error) {
      return Promise.resolve(false);
    }
  }

  function ensureTooltipEl() {
    if (tooltipEl && document.body && document.body.contains(tooltipEl)) {
      return tooltipEl;
    }
    tooltipEl = document.createElement("div");
    tooltipEl.className = "ui-tooltip";
    tooltipEl.setAttribute("role", "tooltip");
    tooltipEl.setAttribute("aria-hidden", "true");
    document.body.appendChild(tooltipEl);
    return tooltipEl;
  }

  function ensureNoticeEl() {
    if (noticeEl && document.body && document.body.contains(noticeEl)) {
      return noticeEl;
    }
    noticeEl = document.createElement("div");
    noticeEl.className = "ui-notice";
    noticeEl.setAttribute("aria-live", "polite");
    noticeEl.setAttribute("aria-atomic", "true");
    document.body.appendChild(noticeEl);
    return noticeEl;
  }

  function showTransientNotice(message, options) {
    var text = trim(message);
    if (!text) {
      return;
    }
    var opts = options || {};
    var node = ensureNoticeEl();
    if (noticeHideTimer) {
      clearTimeout(noticeHideTimer);
      noticeHideTimer = null;
    }
    node.classList.remove("transparent");
    if (opts.transparent) {
      node.classList.add("transparent");
    }
    node.textContent = text;
    node.classList.add("show");
    noticeHideTimer = setTimeout(function () {
      node.classList.remove("show");
      node.classList.remove("transparent");
      noticeHideTimer = null;
    }, 1350);
  }

  function tooltipTextFor(node) {
    if (!node || typeof node.getAttribute !== "function") {
      return "";
    }
    if (node.classList && node.classList.contains("workspace-menu-trigger")) {
      return "";
    }
    var workspaceRow = node.closest && node.closest(".workspace-row[data-workspace-id]");
    if (workspaceRow) {
      var workspaceId = String(workspaceRow.getAttribute("data-workspace-id") || "");
      if (workspaceId && workspaceId === String(state.openWorkspaceMenuWorkspaceId || "")) {
        return "";
      }
    }
    var anchor = node.closest && node.closest(".menu-anchor");
    if (anchor) {
      var openMenu = anchor.querySelector(".floating-menu:not(.hidden), .models-box:not(.hidden)");
      if (openMenu) {
        return "";
      }
    }
    return trim(node.getAttribute("data-tooltip") || "");
  }

  function tooltipPreferredPlacement(target) {
    if (!target || !target.getBoundingClientRect) {
      return "bottom";
    }
    if (target.closest && target.closest(".toolbar")) {
      return "top";
    }
    if (target.closest && target.closest(".composer-row, .session-row, .workspace-sidebar-footer")) {
      return "bottom";
    }
    var rect = target.getBoundingClientRect();
    var viewportHeight = window.innerHeight || document.documentElement.clientHeight || 768;
    var spaceAbove = rect.top;
    var spaceBelow = viewportHeight - rect.bottom;
    return spaceBelow >= spaceAbove ? "bottom" : "top";
  }

  function positionTooltip(target) {
    if (!tooltipEl || !target) {
      return;
    }
    var rect = target.getBoundingClientRect();
    var tipRect = tooltipEl.getBoundingClientRect();
    var viewportWidth = window.innerWidth || document.documentElement.clientWidth || 1024;
    var viewportHeight = window.innerHeight || document.documentElement.clientHeight || 768;
    var left = rect.left + (rect.width - tipRect.width) / 2;
    var placement = tooltipPreferredPlacement(target);
    var top = placement === "top" ? rect.top - tipRect.height - 8 : rect.bottom + 8;

    if (left < 8) {
      left = 8;
    }
    if (left + tipRect.width > viewportWidth - 8) {
      left = Math.max(8, viewportWidth - tipRect.width - 8);
    }
    if (top < 8 || top + tipRect.height > viewportHeight - 8) {
      if (placement === "top") {
        top = rect.bottom + 8;
      } else {
        top = rect.top - tipRect.height - 8;
      }
      if (top < 8) {
        top = 8;
      }
      if (top + tipRect.height > viewportHeight - 8) {
        top = Math.max(8, viewportHeight - tipRect.height - 8);
      }
    }

    tooltipEl.style.left = Math.round(left) + "px";
    tooltipEl.style.top = Math.round(top) + "px";
  }

  function showTooltipFor(target) {
    var text = tooltipTextFor(target);
    if (!text) {
      return;
    }
    var tip = ensureTooltipEl();
    tooltipTarget = target;
    tip.classList.remove("show");
    tip.textContent = text;
    tip.setAttribute("aria-hidden", "false");
    tip.style.left = "-9999px";
    tip.style.top = "-9999px";
    positionTooltip(target);
    tip.classList.add("show");
  }

  function clearTooltipShowTimer() {
    if (tooltipShowTimer) {
      clearTimeout(tooltipShowTimer);
      tooltipShowTimer = null;
    }
    tooltipPendingTarget = null;
  }

  function scheduleTooltipFor(target) {
    var text = tooltipTextFor(target);
    if (!text) {
      clearTooltipShowTimer();
      hideTooltip();
      return;
    }
    clearTooltipShowTimer();
    tooltipPendingTarget = target;
    tooltipShowTimer = setTimeout(function () {
      if (!tooltipPendingTarget || tooltipPendingTarget !== target) {
        return;
      }
      showTooltipFor(target);
      tooltipShowTimer = null;
      tooltipPendingTarget = null;
    }, TOOLTIP_DELAY_MS);
  }

  function hideTooltip() {
    clearTooltipShowTimer();
    tooltipTarget = null;
    if (!tooltipEl) {
      return;
    }
    tooltipEl.classList.remove("show");
    tooltipEl.setAttribute("aria-hidden", "true");
  }

  function hydrateTooltips() {
    var nodes = document.querySelectorAll("button, [role='button'], [aria-label], [title]");
    for (var i = 0; i < nodes.length; i += 1) {
      var node = nodes[i];
      var tip = trim(node.getAttribute("data-tooltip") || "");
      var title = trim(node.getAttribute("title") || "");
      var label = trim(node.getAttribute("aria-label") || "");
      if (!tip) {
        if (title) {
          tip = title;
        } else if (label) {
          tip = label;
        }
      }
      if (tip) {
        node.setAttribute("data-tooltip", tip);
      }
      if (node.hasAttribute("title")) {
        node.removeAttribute("title");
      }
    }
  }

  function waitMs(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  function isRetriableRequestError(error) {
    var message = "";
    if (error && error.message) {
      message = String(error.message || "");
    } else {
      message = String(error || "");
    }
    var lower = message.toLowerCase();
    if (!lower) {
      return false;
    }
    return (
      lower.indexOf("failed to fetch") >= 0 ||
      lower.indexOf("networkerror") >= 0 ||
      lower.indexOf("gateway timeout") >= 0 ||
      lower.indexOf("gateway time-out") >= 0 ||
      lower.indexOf("timed out") >= 0 ||
      lower.indexOf("json.parse") >= 0 ||
      (lower.indexOf("json") >= 0 && lower.indexOf("unexpected") >= 0)
    );
  }

  function runWithRetry(taskFn, attempts, delayMs) {
    var maxAttempts = Number(attempts || 1);
    if (!isFinite(maxAttempts) || maxAttempts < 1) {
      maxAttempts = 1;
    }

    function attempt(index) {
      return Promise.resolve()
        .then(taskFn)
        .catch(function (error) {
          if (index >= maxAttempts - 1 || !isRetriableRequestError(error)) {
            throw error;
          }
          return waitMs(delayMs).then(function () {
            return attempt(index + 1);
          });
        });
    }

    return attempt(0);
  }

  function dirname(pathText) {
    var clean = trim(pathText).replace(/[\\/]+$/, "");
    if (!clean) {
      return "";
    }
    var slash = Math.max(clean.lastIndexOf("/"), clean.lastIndexOf("\\"));
    if (slash <= 0) {
      return clean;
    }
    return clean.slice(0, slash);
  }

  function stripTrailingSlashes(pathText) {
    return String(pathText || "").replace(/[\\/]+$/, "");
  }

  function normalizeSlashes(pathText) {
    return String(pathText || "").replace(/\\/g, "/");
  }

  function denormalizeSlashes(pathText, preferBackslashes) {
    if (preferBackslashes) {
      return String(pathText || "").replace(/\//g, "\\");
    }
    return pathText;
  }

  function deriveDropRootFromFile(file) {
    if (!file || !file.path) {
      return "";
    }

    var filePath = String(file.path);
    var relative = String(file.webkitRelativePath || "");
    if (!relative) {
      return dirname(filePath);
    }

    var normalizedFile = normalizeSlashes(filePath);
    var normalizedRelative = normalizeSlashes(relative).replace(/^\/+/, "");
    if (!normalizedRelative) {
      return dirname(filePath);
    }

    if (normalizedFile.slice(-normalizedRelative.length) !== normalizedRelative) {
      return dirname(filePath);
    }

    var base = normalizedFile.slice(0, normalizedFile.length - normalizedRelative.length);
    var topFolder = normalizedRelative.split("/")[0] || "";
    var root = stripTrailingSlashes(base + topFolder);
    if (!root) {
      return dirname(filePath);
    }

    return denormalizeSlashes(root, filePath.indexOf("\\") >= 0);
  }

  function parseDownloadUrlPath(downloadUrlText) {
    var text = trim(downloadUrlText);
    if (!text) {
      return "";
    }
    var parts = text.split(":");
    if (parts.length < 3) {
      return "";
    }
    var candidate = parts.slice(2).join(":");
    return decodeFileUri(candidate);
  }

  function decodeFileUri(uri) {
    var text = trim(uri);
    if (!/^file:\/\//i.test(text)) {
      return "";
    }
    try {
      var parsed = new URL(text);
      var path = decodeURIComponent(parsed.pathname || "");
      if (/^\/[A-Za-z]:/.test(path)) {
        path = path.slice(1);
      }
      return path;
    } catch (_err) {
      return "";
    }
  }

  function looksLikeAbsolutePath(text) {
    return /^\/.+/.test(text) || /^[A-Za-z]:[\\/].+/.test(text);
  }

  function extractPathFromText(text) {
    var lines = String(text || "").split(/\r?\n/);
    for (var i = 0; i < lines.length; i += 1) {
      var line = trim(lines[i]);
      if (!line) {
        continue;
      }
      var fromUri = decodeFileUri(line);
      if (fromUri) {
        return fromUri;
      }
      if (looksLikeAbsolutePath(line)) {
        return line;
      }
    }
    return "";
  }

  function extractPathFromDataTransfer(dataTransfer) {
    if (!dataTransfer) {
      return "";
    }

    var uriList = dataTransfer.getData("text/uri-list");
    if (uriList) {
      var uriPath = extractPathFromText(uriList);
      if (uriPath) {
        return uriPath;
      }
    }

    var plain = dataTransfer.getData("text/plain");
    if (plain) {
      var plainPath = extractPathFromText(plain);
      if (plainPath) {
        return plainPath;
      }
    }

    var mozUrl = dataTransfer.getData("text/x-moz-url");
    if (mozUrl) {
      var mozPath = extractPathFromText(mozUrl);
      if (mozPath) {
        return mozPath;
      }
    }

    var downloadUrl = dataTransfer.getData("DownloadURL");
    if (downloadUrl) {
      var downloadPath = parseDownloadUrlPath(downloadUrl);
      if (downloadPath) {
        return downloadPath;
      }
    }

    if (dataTransfer.files && dataTransfer.files.length > 0) {
      for (var i = 0; i < dataTransfer.files.length; i += 1) {
        var file = dataTransfer.files[i];
        if (!file) {
          continue;
        }
        var dropRoot = deriveDropRootFromFile(file);
        if (dropRoot) {
          return dropRoot;
        }
        if (file.path) {
          return file.path;
        }
      }
    }

    if (dataTransfer.items && dataTransfer.items.length > 0) {
      for (var j = 0; j < dataTransfer.items.length; j += 1) {
        var item = dataTransfer.items[j];
        if (!item) {
          continue;
        }
        if (item.webkitGetAsEntry) {
          var entry = item.webkitGetAsEntry();
          if (entry && entry.fullPath && looksLikeAbsolutePath(entry.fullPath)) {
            return entry.fullPath;
          }
        }
        var maybeFile = item.getAsFile && item.getAsFile();
        if (maybeFile) {
          var maybeRoot = deriveDropRootFromFile(maybeFile);
          if (maybeRoot) {
            return maybeRoot;
          }
        }
        if (maybeFile && maybeFile.path) {
          return maybeFile.path;
        }
      }
    }

    return "";
  }

  function humanizeModelToken(token) {
    var clean = String(token || "").replace(/[-_]+/g, " ").trim();
    if (!clean) {
      return "Model";
    }

    return clean
      .split(/\s+/)
      .map(function (word) {
        if (!word) {
          return "";
        }
        return word.charAt(0).toUpperCase() + word.slice(1);
      })
      .join(" ");
  }

  function parseModelDisplay(modelName) {
    var raw = trim(modelName);
    if (!raw) {
      return { primary: "Model", meta: "", raw: "" };
    }

    var primaryPart = raw;
    var secondary = "";
    var colon = raw.indexOf(":");
    if (colon >= 0) {
      primaryPart = raw.slice(0, colon);
      secondary = trim(raw.slice(colon + 1));
    }

    var versionPart = "";
    var versionMatch = primaryPart.match(/^(.*?)(\d+(?:\.\d+)*)$/);
    var baseName = primaryPart;
    if (versionMatch && versionMatch[1]) {
      baseName = versionMatch[1];
      versionPart = "v" + versionMatch[2];
    }

    var primary = humanizeModelToken(baseName || primaryPart);
    var metaParts = [];
    if (versionPart) {
      metaParts.push(versionPart);
    }
    if (secondary) {
      metaParts.push(secondary);
    }

    return {
      primary: primary,
      meta: metaParts.join(" / "),
      raw: raw
    };
  }

  var textAttachmentExtensions = {
    txt: 1,
    md: 1,
    markdown: 1,
    rst: 1,
    log: 1,
    csv: 1,
    tsv: 1,
    json: 1,
    xml: 1,
    yaml: 1,
    yml: 1,
    toml: 1,
    ini: 1,
    conf: 1,
    cfg: 1,
    env: 1,
    sh: 1,
    bash: 1,
    zsh: 1,
    fish: 1,
    py: 1,
    js: 1,
    jsx: 1,
    ts: 1,
    tsx: 1,
    c: 1,
    h: 1,
    cpp: 1,
    cc: 1,
    cxx: 1,
    hpp: 1,
    java: 1,
    go: 1,
    rs: 1,
    php: 1,
    rb: 1,
    swift: 1,
    kt: 1,
    scala: 1,
    sql: 1,
    html: 1,
    htm: 1,
    css: 1,
    scss: 1,
    less: 1,
    vue: 1,
    svelte: 1,
    gradle: 1,
    dockerfile: 1,
    makefile: 1
  };

  var attachmentAcceptValue = [
    "image/*",
    "text/*",
    "application/pdf",
    ".md,.markdown,.txt,.rst,.log,.csv,.tsv",
    ".json,.yaml,.yml,.toml,.ini,.conf,.cfg,.env",
    ".sh,.bash,.zsh,.fish",
    ".js,.jsx,.ts,.tsx,.py,.go,.rs,.java,.kt,.swift,.rb,.php,.c,.h,.cpp,.hpp,.cc,.cxx",
    ".html,.htm,.css,.scss,.less,.sql,.xml,.vue,.svelte,.dockerfile,.makefile,.gradle"
  ].join(",");

  function fileExtension(fileName) {
    var name = String(fileName || "");
    var dot = name.lastIndexOf(".");
    if (dot < 0 || dot >= name.length - 1) {
      return "";
    }
    return name.slice(dot + 1).toLowerCase();
  }

  function attachmentKindForFile(file) {
    var mime = String((file && file.type) || "").toLowerCase();
    var ext = fileExtension(file && file.name);

    if (/^image\/(png|jpeg|jpg|gif|webp|bmp|tiff|x-icon|svg\+xml)$/.test(mime)) {
      return "image";
    }

    if (/^text\//.test(mime)) {
      return "text";
    }

    if (/^application\/(json|xml|yaml|x-yaml|toml|javascript|x-javascript|typescript|x-typescript|x-sh|x-shellscript)$/.test(mime)) {
      return "text";
    }

    if (mime === "application/pdf") {
      return "document";
    }

    if (textAttachmentExtensions[ext]) {
      return "text";
    }

    if (ext === "pdf") {
      return "document";
    }

    return "";
  }

  function formatBytes(bytes) {
    var value = Number(bytes || 0);
    if (!isFinite(value) || value <= 0) {
      return "0 B";
    }
    if (value < 1024) {
      return String(Math.round(value)) + " B";
    }
    var kb = value / 1024;
    if (kb < 1024) {
      return String(Math.round(kb)) + " KB";
    }
    var mb = kb / 1024;
    if (mb < 1024) {
      return mb.toFixed(1) + " MB";
    }
    return (mb / 1024).toFixed(1) + " GB";
  }

  function newClientAttachmentId() {
    return "att-" + Date.now() + "-" + String(Math.floor(Math.random() * 999999));
  }

  function requestJson(url, options) {
    var controller = new AbortController();
    var timeoutMs = Number(options && options.timeoutMs ? options.timeoutMs : 30000);
    if (!isFinite(timeoutMs) || timeoutMs <= 0) {
      timeoutMs = 30000;
    }
    return new Promise(function (resolve, reject) {
      var settled = false;
      var timeoutErrorText = "Request timed out after " + Math.round(timeoutMs / 1000) + "s.";
      var timeoutId = setTimeout(function () {
        if (settled) {
          return;
        }
        settled = true;
        try {
          controller.abort();
        } catch (_abortErr) {
          // Ignore abort failures; timeout already finalized.
        }
        reject(new Error(timeoutErrorText));
      }, timeoutMs);

      fetch(url, {
        method: options.method,
        headers: options.headers,
        body: options.body,
        cache: options.cacheMode || "default",
        signal: controller.signal
      })
        .then(function (response) {
          return response.text().then(function (raw) {
            if (!response.ok) {
              throw new Error("Request failed (" + response.status + "): " + raw.slice(0, 220));
            }
            try {
              return JSON.parse(raw);
            } catch (_err) {
              throw new Error("Server returned non-JSON response: " + raw.slice(0, 220));
            }
          });
        })
        .then(function (json) {
          if (settled) {
            return;
          }
          settled = true;
          clearTimeout(timeoutId);
          resolve(json);
        })
        .catch(function (err) {
          if (settled) {
            return;
          }
          settled = true;
          clearTimeout(timeoutId);
          if (err && err.name === "AbortError") {
            reject(new Error(timeoutErrorText));
            return;
          }
          reject(err);
        });
    });
  }

  function apiGet(action, params, options) {
    var search = new URLSearchParams(params || {});
    search.set("action", action);
    search.set("_ts", String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000)));
    var timeoutMs = 30000;
    if (options && Number(options.timeoutMs) > 0) {
      timeoutMs = Number(options.timeoutMs);
    }
    return requestJson("/cgi/artificer-api?" + search.toString(), {
      method: "GET",
      headers: { Accept: "application/json" },
      cacheMode: "no-store",
      timeoutMs: timeoutMs
    });
  }

  function apiPost(action, data, options) {
    var timeoutMs = 30000;
    if (action === "run") {
      var computeBudget = normalizeComputeBudget(data && data.compute_budget ? data.compute_budget : state.computeBudget);
      timeoutMs = computeBudgetRequestTimeoutMs(computeBudget, data || {});
      if (!isFinite(timeoutMs) || timeoutMs < 30000) {
        timeoutMs = 30000;
      }
    } else if (options && Number(options.timeoutMs) > 0) {
      timeoutMs = Number(options.timeoutMs);
    }
    var body = new URLSearchParams(data || {});
    body.set("action", action);
    return requestJson("/cgi/artificer-api", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        Accept: "application/json"
      },
      body: body.toString(),
      timeoutMs: timeoutMs
    });
  }

  function setControlPending(control, isPending, options) {
    var node = control && control.nodeType === 1 ? control : null;
    if (!node || !node.classList) {
      return;
    }

    var pending = !!isPending;
    if (pending && String(node.getAttribute("data-ui-pending") || "") === "1") {
      return;
    }
    if (!pending && String(node.getAttribute("data-ui-pending") || "") !== "1") {
      return;
    }

    if (pending) {
      node.setAttribute("data-ui-pending", "1");
      node.setAttribute("aria-busy", "true");
      node.classList.add("ui-pending");

      var allowSpinner = !(options && options.spinner === false);
      if (allowSpinner && node.tagName === "BUTTON") {
        var width = 0;
        try {
          width = Math.round(node.getBoundingClientRect().width || 0);
        } catch (_err) {
          width = 0;
        }
        if (width >= 56) {
          node.classList.add("ui-pending-spinner");
        }
      }

      if ("disabled" in node) {
        node.setAttribute("data-ui-pending-was-disabled", node.disabled ? "1" : "0");
        node.disabled = true;
      } else {
        node.setAttribute("data-ui-pending-block-pointer", "1");
      }
      return;
    }

    node.removeAttribute("data-ui-pending");
    node.removeAttribute("aria-busy");
    node.classList.remove("ui-pending");
    node.classList.remove("ui-pending-spinner");

    if ("disabled" in node) {
      var wasDisabled = node.getAttribute("data-ui-pending-was-disabled") === "1";
      node.removeAttribute("data-ui-pending-was-disabled");
      if (!wasDisabled) {
        node.disabled = false;
      }
    } else {
      node.removeAttribute("data-ui-pending-block-pointer");
    }
  }

  function runWithControlPending(control, runner, options) {
    var node = control && control.nodeType === 1 ? control : null;
    if (node && String(node.getAttribute("data-ui-pending") || "") === "1") {
      return Promise.resolve(null);
    }
    if (node) {
      setControlPending(node, true, options);
    }
    return Promise.resolve()
      .then(function () {
        if (typeof runner === "function") {
          return runner();
        }
        return null;
      })
      .finally(function () {
        if (node) {
          setControlPending(node, false, options);
        }
      });
  }

  function getWorkspaceById(workspaceId) {
    for (var i = 0; i < state.workspaces.length; i += 1) {
      if (state.workspaces[i].id === workspaceId) {
        return state.workspaces[i];
      }
    }
    return null;
  }

  function activeWorkspace() {
    if (!state.activeWorkspaceId) {
      return null;
    }
    return getWorkspaceById(state.activeWorkspaceId);
  }

  function getConversationById(workspace, conversationId) {
    if (!workspace || !workspace.conversations) {
      return null;
    }
    for (var i = 0; i < workspace.conversations.length; i += 1) {
      if (workspace.conversations[i].id === conversationId) {
        return workspace.conversations[i];
      }
    }
    return null;
  }

  function findWorkspaceIdForConversation(conversationId) {
    var targetId = String(conversationId || "");
    if (!targetId) {
      return "";
    }
    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      if (!workspace || !Array.isArray(workspace.conversations)) {
        continue;
      }
      for (var j = 0; j < workspace.conversations.length; j += 1) {
        var conversation = workspace.conversations[j];
        if (conversation && String(conversation.id || "") === targetId) {
          return String(workspace.id || "");
        }
      }
    }
    return "";
  }

  function queueNumber(value) {
    var parsed = Number(value || 0);
    if (!isFinite(parsed) || parsed < 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  function conversationReadKey(workspaceId, conversationId) {
    return String(workspaceId || "") + "::" + String(conversationId || "");
  }

  function cloneConversationData(conversation) {
    if (!conversation || typeof conversation !== "object") {
      return null;
    }
    try {
      return JSON.parse(JSON.stringify(conversation));
    } catch (_err) {
      return null;
    }
  }

  function cacheConversationSnapshot(workspaceId, conversationId, conversation) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId || !conversation || typeof conversation !== "object") {
      return;
    }
    var cloned = cloneConversationData(conversation);
    if (!cloned) {
      return;
    }
    if (!cloned.id) {
      cloned.id = convId;
    }
    state.conversationCacheByKey[conversationReadKey(wsId, convId)] = cloned;
  }

  function cacheActiveConversationSnapshot(workspaceId, conversationId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId || !state.activeConversation) {
      return;
    }
    if (
      String(state.activeWorkspaceId || "") !== wsId ||
      String(state.activeConversationId || "") !== convId ||
      String(state.activeConversation.id || "") !== convId
    ) {
      return;
    }
    cacheConversationSnapshot(wsId, convId, state.activeConversation);
  }

  function normalizeDecisionRequest(request) {
    var source = request && typeof request === "object" ? request : null;
    if (!source) {
      return null;
    }
    var question = trim(String(source.question || ""));
    if (!question) {
      return null;
    }
    var optionsRaw = Array.isArray(source.options) ? source.options : [];
    var options = [];
    for (var i = 0; i < optionsRaw.length; i += 1) {
      var optionText = trim(String(optionsRaw[i] || ""));
      if (!optionText) {
        continue;
      }
      if (optionText.toLowerCase() === "other") {
        continue;
      }
      options.push(optionText);
      if (options.length >= 5) {
        break;
      }
    }
    if (!options.length) {
      return null;
    }
    return {
      question: question,
      options: options
    };
  }

  function normalizeApprovalRequest(request) {
    var source = request && typeof request === "object" ? request : null;
    if (!source) {
      return null;
    }
    var command = trim(String(source.command || ""));
    if (!command) {
      return null;
    }
    return {
      command: command,
      reason: trim(String(source.reason || ""))
    };
  }

  function asArrayCopy(value) {
    if (!Array.isArray(value)) {
      return [];
    }
    return value.slice(0);
  }

  function normalizeModeRuntime(payload) {
    var source = payload && typeof payload === "object" ? payload : {};
    var scheduler = source.scheduler && typeof source.scheduler === "object" ? source.scheduler : {};
    var cooperation = source.cooperation && typeof source.cooperation === "object" ? source.cooperation : {};
    var modesRaw = asArrayCopy(source.modes);
    var skillsRaw = asArrayCopy(source.skills);
    var panelsRaw = asArrayCopy(source.panels);
    var directivesRaw = asArrayCopy(cooperation.recent);
    var modes = [];
    var skills = [];
    var panels = [];
    var directives = [];

    for (var i = 0; i < modesRaw.length; i += 1) {
      var mode = modesRaw[i];
      if (!mode || typeof mode !== "object") {
        continue;
      }
      var modeId = trim(String(mode.id || ""));
      if (!modeId) {
        continue;
      }
      modes.push({
        id: modeId,
        name: trim(String(mode.name || modeId)),
        description: trim(String(mode.description || "")),
        enabled: Number(mode.enabled || 0) > 0,
        priority: queueNumber(mode.priority || 0),
        cadence_sec: queueNumber(mode.cadence_sec || 0),
        interrupt_rights: Number(mode.interrupt_rights || 0) > 0,
        allow_queue_injection: Number(mode.allow_queue_injection || 0) > 0,
        status: trim(String(mode.status || "idle")),
        drift_score: trim(String(mode.drift_score || "0.00")),
        last_tick: trim(String(mode.last_tick || "")),
        next_tick: trim(String(mode.next_tick || "")),
        goal_state: trim(String(mode.goal_state || "")),
        last_skill_plan: asArrayCopy(mode.last_skill_plan),
        last_directive_count: trim(String(mode.last_directive_count || "0")),
        last_directive_emits: trim(String(mode.last_directive_emits || "0")),
        last_directive_summary: trim(String(mode.last_directive_summary || "none")),
        telemetry_subscriptions: asArrayCopy(mode.telemetry_subscriptions),
        allowed_capabilities: asArrayCopy(mode.allowed_capabilities)
      });
    }

    for (var j = 0; j < skillsRaw.length; j += 1) {
      var skill = skillsRaw[j];
      if (!skill || typeof skill !== "object") {
        continue;
      }
      var skillId = trim(String(skill.id || ""));
      if (!skillId) {
        continue;
      }
      skills.push({
        id: skillId,
        name: trim(String(skill.name || skillId)),
        description: trim(String(skill.description || "")),
        trigger: trim(String(skill.trigger || "")),
        capabilities: asArrayCopy(skill.capabilities),
        stateless: skill.stateless !== false,
        interrupt_authority: skill.interrupt_authority === true,
        files: skill.files && typeof skill.files === "object" ? skill.files : {}
      });
    }

    for (var k = 0; k < panelsRaw.length; k += 1) {
      var panel = panelsRaw[k];
      if (!panel || typeof panel !== "object") {
        continue;
      }
      var panelId = trim(String(panel.id || ""));
      if (!panelId) {
        continue;
      }
      panels.push({
        id: panelId,
        title: trim(String(panel.title || panelId)),
        summary: trim(String(panel.summary || "")),
        stream: trim(String(panel.stream || "")),
        metrics: asArrayCopy(panel.metrics)
      });
    }

    for (var d = 0; d < directivesRaw.length; d += 1) {
      var directive = directivesRaw[d];
      if (!directive || typeof directive !== "object") {
        continue;
      }
      directives.push({
        timestamp: trim(String(directive.timestamp || "")),
        from_mode: trim(String(directive.from_mode || "")),
        to_mode: trim(String(directive.to_mode || "")),
        kind: trim(String(directive.kind || "")),
        priority: trim(String(directive.priority || "")),
        payload: trim(String(directive.payload || "")),
        expires_epoch: trim(String(directive.expires_epoch || "")),
        expired: Number(directive.expired || 0) > 0 || directive.expired === true
      });
    }

    modes.sort(function (a, b) {
      var priorityDiff = Number(b.priority || 0) - Number(a.priority || 0);
      if (priorityDiff !== 0) {
        return priorityDiff;
      }
      return String(a.name || a.id || "").localeCompare(String(b.name || b.id || ""));
    });
    skills.sort(function (a, b) {
      return String(a.name || a.id || "").localeCompare(String(b.name || b.id || ""));
    });

    return {
      scheduler: {
        last_tick: trim(String(scheduler.last_tick || "")),
        last_tick_iso: trim(String(scheduler.last_tick_iso || "")),
        ticks: trim(String(scheduler.ticks || "0")),
        last_due_modes: trim(String(scheduler.last_due_modes || "0")),
        last_injections: trim(String(scheduler.last_injections || "0")),
        last_directives_received: trim(String(scheduler.last_directives_received || "0")),
        last_directives_emitted: trim(String(scheduler.last_directives_emitted || "0")),
        summary: trim(String(scheduler.summary || ""))
      },
      modes: modes,
      skills: skills,
      panels: panels,
      cooperation: {
        pending_total: trim(String(cooperation.pending_total || "0")),
        modes_with_pending: trim(String(cooperation.modes_with_pending || "0")),
        recent: directives
      }
    };
  }

  function conversationDecisionRequest(conversation) {
    return normalizeDecisionRequest(conversation && conversation.decision_request ? conversation.decision_request : null);
  }

  function conversationApprovalRequest(conversation) {
    return normalizeApprovalRequest(conversation && conversation.approval_request ? conversation.approval_request : null);
  }

  function setConversationDecisionRequest(workspaceId, conversationId, request) {
    var workspace = getWorkspaceById(workspaceId);
    var conversation = getConversationById(workspace, conversationId);
    if (!conversation) {
      return;
    }
    conversation.decision_request = normalizeDecisionRequest(request);
  }

  function setAwaitingApprovalState(workspaceId, conversationId, value) {
    if (!workspaceId || !conversationId) {
      return;
    }
    var key = conversationReadKey(workspaceId, conversationId);
    if (value) {
      state.awaitingApprovalByConversation[key] = 1;
    } else if (state.awaitingApprovalByConversation[key]) {
      delete state.awaitingApprovalByConversation[key];
    }
  }

  function isAwaitingApprovalConversation(workspaceId, conversationId) {
    if (!workspaceId || !conversationId) {
      return false;
    }
    var key = conversationReadKey(workspaceId, conversationId);
    return !!state.awaitingApprovalByConversation[key];
  }

  function updateAwaitingApprovalFromQueueSnapshot(workspaceId, conversationId, snapshot) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return;
    }
    var data = snapshot || {};
    var lastStatus = String(data.lastStatus || "");
    var hasApprovalRequest = !!normalizeApprovalRequest(data.approvalRequest);
    var pending = queueNumber(data.pending);
    var running = !!data.running;

    if (lastStatus === "awaiting_approval" || hasApprovalRequest) {
      setAwaitingApprovalState(wsId, convId, true);
      return;
    }

    var explicitNotAwaiting = (
      lastStatus === "done" ||
      lastStatus === "error" ||
      lastStatus === "cancelled" ||
      lastStatus === "awaiting_decision" ||
      running ||
      pending > 0
    );
    if (explicitNotAwaiting) {
      setAwaitingApprovalState(wsId, convId, false);
    }
  }

  function conversationUpdatedNumber(conversation) {
    var parsed = Number(conversation && conversation.updated || 0);
    if (!isFinite(parsed) || parsed < 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  function conversationCreatedNumber(conversation) {
    var parsed = Number(conversation && conversation.created || 0);
    if (!isFinite(parsed) || parsed < 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  function persistSeenConversationState() {
    try {
      window.localStorage.setItem(
        seenConversationStorageKey,
        JSON.stringify(state.seenConversationUpdatedByKey || {})
      );
    } catch (_err) {
      return;
    }
  }

  function seenUpdatedForConversation(workspaceId, conversationId) {
    var key = conversationReadKey(workspaceId, conversationId);
    return parseSeenUpdatedValue(state.seenConversationUpdatedByKey[key]);
  }

  function markConversationSeen(workspaceId, conversationId, conversation) {
    if (!workspaceId || !conversationId) {
      return;
    }

    var updated = conversationUpdatedNumber(conversation);
    if (updated <= 0) {
      var workspace = getWorkspaceById(workspaceId);
      var fallbackConversation = getConversationById(workspace, conversationId);
      updated = conversationUpdatedNumber(fallbackConversation);
    }
    if (updated <= 0) {
      updated = Math.floor(Date.now() / 1000);
    }

    var key = conversationReadKey(workspaceId, conversationId);
    var previous = parseSeenUpdatedValue(state.seenConversationUpdatedByKey[key]);
    if (previous >= updated) {
      return;
    }

    state.seenConversationUpdatedByKey[key] = updated;
    persistSeenConversationState();
  }

  function bootstrapSeenConversationsIfNeeded() {
    if (!state.seenConversationBootstrapPending) {
      return;
    }

    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      var workspaceId = workspace && workspace.id ? workspace.id : "";
      if (!workspaceId || !workspace || !Array.isArray(workspace.conversations)) {
        continue;
      }
      for (var j = 0; j < workspace.conversations.length; j += 1) {
        var conversation = workspace.conversations[j] || {};
        if (!conversation.id) {
          continue;
        }
        var updated = conversationUpdatedNumber(conversation);
        if (updated <= 0) {
          continue;
        }
        state.seenConversationUpdatedByKey[conversationReadKey(workspaceId, conversation.id)] = updated;
      }
    }

    state.seenConversationBootstrapPending = false;
    persistSeenConversationState();
  }

  function pruneSeenConversationState() {
    var valid = {};
    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      if (!workspace || !workspace.id || !Array.isArray(workspace.conversations)) {
        continue;
      }
      for (var j = 0; j < workspace.conversations.length; j += 1) {
        var conversation = workspace.conversations[j] || {};
        if (!conversation.id) {
          continue;
        }
        valid[conversationReadKey(workspace.id, conversation.id)] = true;
      }
    }

    var changed = false;
    var existingKeys = Object.keys(state.seenConversationUpdatedByKey || {});
    for (var k = 0; k < existingKeys.length; k += 1) {
      var key = existingKeys[k];
      if (!valid[key]) {
        delete state.seenConversationUpdatedByKey[key];
        changed = true;
      }
    }

    if (changed) {
      persistSeenConversationState();
    }
  }

  function isConversationUnread(workspaceId, conversation) {
    if (!workspaceId || !conversation || !conversation.id) {
      return false;
    }
    var updated = conversationUpdatedNumber(conversation);
    if (updated <= 0) {
      return false;
    }
    return updated > seenUpdatedForConversation(workspaceId, conversation.id);
  }

  function queueStatsForConversation(workspaceId, conversationId) {
    var workspace = getWorkspaceById(workspaceId);
    var conversation = getConversationById(workspace, conversationId);
    if (!conversation) {
      return {
        pending: 0,
        running: false,
        done: false,
        lastStatus: "",
        firstId: ""
      };
    }

    return {
      pending: queueNumber(conversation.queue_pending),
      running: String(conversation.queue_running || "0") === "1",
      done: String(conversation.queue_done || "0") === "1",
      lastStatus: String(conversation.queue_last_status || ""),
      firstId: String(conversation.queue_first_id || "")
    };
  }

  function setConversationQueueFields(workspaceId, conversationId, patch) {
    var workspace = getWorkspaceById(workspaceId);
    var conversation = getConversationById(workspace, conversationId);
    if (!conversation || !patch) {
      return;
    }

    if (typeof patch.pending !== "undefined") {
      conversation.queue_pending = String(queueNumber(patch.pending));
    }
    if (typeof patch.running !== "undefined") {
      conversation.queue_running = patch.running ? "1" : "0";
    }
    if (typeof patch.done !== "undefined") {
      conversation.queue_done = patch.done ? "1" : "0";
    }
    if (typeof patch.lastStatus !== "undefined") {
      conversation.queue_last_status = String(patch.lastStatus || "");
    }
    if (typeof patch.firstId !== "undefined") {
      conversation.queue_first_id = String(patch.firstId || "");
    }
    if (typeof patch.decisionRequest !== "undefined") {
      conversation.decision_request = normalizeDecisionRequest(patch.decisionRequest);
    }
    if (typeof patch.approvalRequest !== "undefined") {
      conversation.approval_request = normalizeApprovalRequest(patch.approvalRequest);
    }
  }

  function activeConversationQueueStats() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      return {
        pending: 0,
        running: false,
        done: false,
        lastStatus: "",
        firstId: ""
      };
    }
    return queueStatsForConversation(state.activeWorkspaceId, state.activeConversationId);
  }

  function queueConversationKey(workspaceId, conversationId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return "";
    }
    return conversationReadKey(wsId, convId);
  }

  function normalizeQueueListItem(source) {
    var item = source && typeof source === "object" ? source : {};
    return {
      id: String(item.id || ""),
      order: String(item.order || ""),
      prompt: String(item.prompt || ""),
      run_mode: normalizeRunMode(item.run_mode || "auto"),
      assistant_mode_id: normalizeAssistantModeId(item.assistant_mode_id || ""),
      compute_budget: normalizeComputeBudget(item.compute_budget || "auto"),
      command_exec_mode: normalizeCommandExecModeValue(item.command_exec_mode || ""),
      permission_mode: normalizePermissionModeValue(item.permission_mode || ""),
      explicit_skill_ids: Array.isArray(item.explicit_skill_ids) ? item.explicit_skill_ids : []
    };
  }

  function queueItemsForConversation(workspaceId, conversationId) {
    var key = queueConversationKey(workspaceId, conversationId);
    if (!key) {
      return [];
    }
    var list = state.queueItemsByConversation[key];
    return Array.isArray(list) ? list : [];
  }

  function setQueueItemsForConversation(workspaceId, conversationId, items) {
    var key = queueConversationKey(workspaceId, conversationId);
    if (!key) {
      return;
    }
    if (!Array.isArray(items) || !items.length) {
      delete state.queueItemsByConversation[key];
      return;
    }
    state.queueItemsByConversation[key] = items;
  }

  function clearQueueItemsForConversation(workspaceId, conversationId) {
    var key = queueConversationKey(workspaceId, conversationId);
    if (!key) {
      return;
    }
    delete state.queueItemsByConversation[key];
    delete state.queueItemsLoadingByConversation[key];
    delete state.queueItemsFetchedAtByConversation[key];
  }

  function clearQueueEditState() {
    state.queueEdit.workspaceId = "";
    state.queueEdit.conversationId = "";
    state.queueEdit.itemId = "";
    state.queueEdit.draftText = "";
    state.queueEdit.saving = false;
  }

  function beginQueueItemEdit(workspaceId, conversationId, itemId, initialText) {
    state.queueEdit.workspaceId = String(workspaceId || "");
    state.queueEdit.conversationId = String(conversationId || "");
    state.queueEdit.itemId = String(itemId || "");
    state.queueEdit.draftText = String(initialText || "");
    state.queueEdit.saving = false;
  }

  function isQueueEditForConversation(workspaceId, conversationId) {
    return (
      !!state.queueEdit.itemId &&
      String(state.queueEdit.workspaceId || "") === String(workspaceId || "") &&
      String(state.queueEdit.conversationId || "") === String(conversationId || "")
    );
  }

  function queueItemPreview(promptText, maxLength) {
    var raw = trim(String(promptText || "").replace(/\s+/g, " "));
    var limit = Number(maxLength || 0);
    if (!isFinite(limit) || limit < 32) {
      limit = 220;
    }
    if (raw.length <= limit) {
      return raw;
    }
    return raw.slice(0, limit - 1) + "…";
  }

  function isConversationQueueBlockedByEdit(workspaceId, conversationId) {
    if (!isQueueEditForConversation(workspaceId, conversationId)) {
      return false;
    }
    var editingItemId = String(state.queueEdit.itemId || "");
    if (!editingItemId) {
      return false;
    }
    var stats = queueStatsForConversation(workspaceId, conversationId);
    if (stats.firstId && stats.firstId === editingItemId) {
      return true;
    }
    var items = queueItemsForConversation(workspaceId, conversationId);
    if (items.length && String(items[0].id || "") === editingItemId) {
      return true;
    }
    return false;
  }

  function loadQueueItems(workspaceId, conversationId, options) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return Promise.resolve([]);
    }
    var opts = options || {};
    var force = !!opts.force;
    var key = queueConversationKey(wsId, convId);
    if (!key) {
      return Promise.resolve([]);
    }
    if (!force && state.queueItemsLoadingByConversation[key]) {
      return Promise.resolve(queueItemsForConversation(wsId, convId));
    }
    var minIntervalMs = Number(opts.minIntervalMs || 0);
    if (!isFinite(minIntervalMs) || minIntervalMs < 0) {
      minIntervalMs = 0;
    }
    if (!force && minIntervalMs > 0) {
      var fetchedAt = Number(state.queueItemsFetchedAtByConversation[key] || 0);
      if (fetchedAt > 0 && Date.now() - fetchedAt < minIntervalMs) {
        return Promise.resolve(queueItemsForConversation(wsId, convId));
      }
    }

    state.queueItemsLoadingByConversation[key] = true;
    var limit = Number(opts.limit || 24);
    if (!isFinite(limit) || limit < 1) {
      limit = 24;
    }
    if (limit > 80) {
      limit = 80;
    }

    return apiGet("queue_list", {
      workspace_id: wsId,
      conversation_id: convId,
      limit: String(limit)
    }, { timeoutMs: 12000 })
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Could not load queued messages");
        }
        var rawItems = Array.isArray(response.items) ? response.items : [];
        var normalizedItems = [];
        for (var i = 0; i < rawItems.length; i += 1) {
          var normalized = normalizeQueueListItem(rawItems[i]);
          if (!normalized.id) {
            continue;
          }
          normalizedItems.push(normalized);
        }
        setQueueItemsForConversation(wsId, convId, normalizedItems);
        state.queueItemsFetchedAtByConversation[key] = Date.now();
        applyQueueStateFromResponse(wsId, convId, response);

        if (isQueueEditForConversation(wsId, convId)) {
          var editingItemId = String(state.queueEdit.itemId || "");
          var stillExists = false;
          for (var j = 0; j < normalizedItems.length; j += 1) {
            if (String(normalizedItems[j].id || "") === editingItemId) {
              stillExists = true;
              break;
            }
          }
          if (!stillExists) {
            clearQueueEditState();
          }
        }
        return normalizedItems;
      })
      .finally(function () {
        delete state.queueItemsLoadingByConversation[key];
      });
  }

  function workspaceUpdatedScore(workspace) {
    if (!workspace || !workspace.conversations || workspace.conversations.length === 0) {
      return 0;
    }
    var max = 0;
    for (var i = 0; i < workspace.conversations.length; i += 1) {
      var score = Number(workspace.conversations[i].updated || 0);
      if (score > max) {
        max = score;
      }
    }
    return max;
  }

  function workspaceCreatedScore(workspace) {
    if (!workspace || !workspace.conversations || workspace.conversations.length === 0) {
      return 0;
    }
    var max = 0;
    for (var i = 0; i < workspace.conversations.length; i += 1) {
      var score = conversationCreatedNumber(workspace.conversations[i]);
      if (score > max) {
        max = score;
      }
    }
    return max;
  }

  function getSortedWorkspaces() {
    var list = state.workspaces.slice();
    list.sort(function (a, b) {
      var au = state.sortMode === "created" ? workspaceCreatedScore(a) : workspaceUpdatedScore(a);
      var bu = state.sortMode === "created" ? workspaceCreatedScore(b) : workspaceUpdatedScore(b);
      if (au !== bu) {
        return bu - au;
      }
      return String(a.name || "").localeCompare(String(b.name || ""));
    });
    return list;
  }

  function getSortedConversations(workspace) {
    var list = workspace && workspace.conversations ? workspace.conversations.slice() : [];
    list.sort(function (a, b) {
      var aScore = state.sortMode === "created" ? conversationCreatedNumber(a) : conversationUpdatedNumber(a);
      var bScore = state.sortMode === "created" ? conversationCreatedNumber(b) : conversationUpdatedNumber(b);
      if (aScore !== bScore) {
        return bScore - aScore;
      }
      return String(a.title || "").localeCompare(String(b.title || ""));
    });
    return list;
  }

  function findNextQueuedConversation() {
    if (state.activeWorkspaceId && state.activeConversationId) {
      var activeStats = queueStatsForConversation(state.activeWorkspaceId, state.activeConversationId);
      if (activeStats.pending > 0 && !isConversationQueueBlockedByEdit(state.activeWorkspaceId, state.activeConversationId)) {
        return {
          workspaceId: state.activeWorkspaceId,
          conversationId: state.activeConversationId
        };
      }
    }

    var workspaces = getSortedWorkspaces();
    for (var i = 0; i < workspaces.length; i += 1) {
      var conversations = getSortedConversations(workspaces[i]);
      for (var j = 0; j < conversations.length; j += 1) {
        if (
          queueNumber(conversations[j].queue_pending) > 0 &&
          !isConversationQueueBlockedByEdit(workspaces[i].id, conversations[j].id)
        ) {
          return {
            workspaceId: workspaces[i].id,
            conversationId: conversations[j].id
          };
        }
      }
    }

    return null;
  }

  function hasDraftForWorkspace(workspace) {
    if (!workspace) {
      return false;
    }
    if (state.activeDraftWorkspaceId === workspace.id) {
      return true;
    }
    if (workspace.draft_exists === "1") {
      return true;
    }
    if (trim(state.draftTextByWorkspace[workspace.id])) {
      return true;
    }
    return false;
  }

  function isConversationRelevant(workspaceId, conversation) {
    if (!conversation) {
      return false;
    }
    if (workspaceId === state.activeWorkspaceId && conversation.id === state.activeConversationId) {
      return true;
    }
    if (conversationDecisionRequest(conversation)) {
      return true;
    }
    if (String(conversation.queue_last_status || "") === "awaiting_decision") {
      return true;
    }
    if (String(conversation.queue_last_status || "") === "awaiting_approval") {
      return true;
    }
    if (isAwaitingApprovalConversation(workspaceId, conversation.id)) {
      return true;
    }
    if (queueNumber(conversation.queue_pending) > 0) {
      return true;
    }
    if (String(conversation.queue_running || "0") === "1") {
      return true;
    }
    if (String(conversation.queue_done || "0") === "1" && isConversationUnread(workspaceId, conversation)) {
      return true;
    }
    return false;
  }

  function isConversationRunning(workspaceId, conversation) {
    if (!workspaceId || !conversation || !conversation.id) {
      return false;
    }
    var events = runEventsForConversation(conversation.id);
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") === "running") {
        return true;
      }
    }
    if (String(conversation.queue_running || "0") === "1") {
      return true;
    }
    if (String(conversation.queue_last_status || "") === "running") {
      return true;
    }
    if (
      state.busy &&
      String(state.runningWorkspaceId || "") === String(workspaceId) &&
      String(state.runningConversationId || "") === String(conversation.id)
    ) {
      return true;
    }
    return false;
  }

  function formatAgeShort(epochSeconds) {
    var ts = Number(epochSeconds || 0);
    if (!isFinite(ts) || ts <= 0) {
      return "now";
    }
    var now = Math.floor(Date.now() / 1000);
    var diff = now - Math.floor(ts);
    if (diff < 0) {
      diff = 0;
    }
    if (diff < 60) {
      return "now";
    }
    if (diff < 3600) {
      return Math.floor(diff / 60) + "m";
    }
    if (diff < 86400) {
      return Math.floor(diff / 3600) + "h";
    }
    if (diff < 86400 * 30) {
      return Math.floor(diff / 86400) + "d";
    }
    if (diff < 86400 * 365) {
      return Math.floor(diff / (86400 * 30)) + "mo";
    }
    return Math.floor(diff / (86400 * 365)) + "y";
  }

  function conversationStatusPillMarkup(workspaceId, conversation) {
    if (!workspaceId || !conversation || !conversation.id) {
      return "";
    }
    var lastStatus = String(conversation.queue_last_status || "");
    var awaitingApproval = isAwaitingApprovalConversation(workspaceId, conversation.id) || lastStatus === "awaiting_approval";
    if (awaitingApproval) {
      return "<span class='thread-status-pill approval'><span class='pill-spinner' aria-hidden='true'></span><span>Awaiting approval</span></span>";
    }
    var decisionRequest = conversationDecisionRequest(conversation);
    if (decisionRequest || lastStatus === "awaiting_decision") {
      return "<span class='thread-status-pill decision'>Awaiting decision</span>";
    }
    return "";
  }

  function conversationMetaMarkup(workspaceId, conversation) {
    var gitState = state.gitByWorkspace[workspaceId] || {};
    var add = Number(gitState.added || 0);
    var del = Number(gitState.deleted || 0);
    var hasDiff = add > 0 || del > 0;
    var age = formatAgeShort(conversationCreatedNumber(conversation));
    var conversationId = conversation && conversation.id ? conversation.id : "";
    var archiveKey = conversationReadKey(workspaceId, conversationId);
    var isArchiveArmed = archiveKey === state.pendingArchiveKey;
    var isArchiveSubmitting = archiveKey === state.pendingArchiveSubmittingKey;
    var html = "<span class='conversation-meta' title='Project diff since last commit'>";
    if (hasDiff) {
      html += "<span class='meta-diff'>";
      html += "<span class='meta-add' title='Lines added since last commit'>+" + escHtml(String(add)) + "</span>";
      html += "<span class='meta-del' title='Lines removed since last commit'>-" + escHtml(String(del)) + "</span>";
      html += "</span>";
    }
    html += "<span class='meta-age-slot'>";
    html += "<span class='meta-age' title='Thread age'>" + ((isArchiveArmed || isArchiveSubmitting) ? "" : escHtml(age)) + "</span>";
    html += archiveControlMarkup(workspaceId, conversationId);
    html += "</span></span>";
    return html;
  }

  function conversationDisplayTitle(title) {
    var text = String(title || "Thread");
    text = text.replace(/[.](?:[\s\u00a0]+[.]){2,}/g, "...");
    text = text.replace(/…+/g, "...");
    text = text.replace(/\s+/g, " ").trim();
    return text || "Thread";
  }

  function archiveControlMarkup(workspaceId, conversationId) {
    var key = conversationReadKey(workspaceId, conversationId);
    var isArmed = key === state.pendingArchiveKey;
    var isSubmitting = key === state.pendingArchiveSubmittingKey;
    if (!isArmed) {
      return (
        "<button type='button' class='thread-archive-btn' title='Archive thread' data-action='arm-archive-conversation' data-workspace-id='" + escHtml(workspaceId) + "' data-conversation-id='" + escHtml(conversationId) + "'><span class='archive-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><rect x='2.4' y='3.2' width='11.2' height='9.2' rx='1.4'></rect><path d='M4.5 6.1h7'></path><path d='M6 8.3h4'></path></svg></span></button>"
      );
    }

    var ready = !isSubmitting && Date.now() >= Number(state.pendingArchiveReadyAt || 0);
    var disabledAttr = ready ? "" : " disabled";
    var readyClass = ready ? " ready" : "";
    var loadingClass = isSubmitting ? " loading" : "";
    var label = isSubmitting
      ? "<span class='thread-confirm-spinner' aria-hidden='true'></span><span>Archiving...</span>"
      : "Confirm";
    return (
      "<button type='button' class='thread-confirm-btn" + readyClass + loadingClass + "' data-action='confirm-archive-conversation' data-workspace-id='" + escHtml(workspaceId) + "' data-conversation-id='" + escHtml(conversationId) + "'" + disabledAttr + ">" + label + "</button>"
    );
  }

  function activeModelName() {
    if (state.activeConversation && state.activeConversation.model) {
      return state.activeConversation.model;
    }

    if (state.activeDraftWorkspaceId && state.draftModelByWorkspace[state.activeDraftWorkspaceId]) {
      return state.draftModelByWorkspace[state.activeDraftWorkspaceId];
    }

    if (state.models.length > 0) {
      return state.models[0];
    }

    return "";
  }

  function normalizePermissionToggles() {
    if (!state.networkAccess && state.webAccess) {
      state.webAccess = false;
      storageSet("artificer.webAccess", "0");
    }
  }

  function permissionModeLabel(mode) {
    switch (mode) {
      case "workspace-write":
        return "Project write";
      case "read-only":
        return "Read only";
      case "full-access":
        return "Full access";
      default:
        return "Default permissions";
    }
  }

  function permissionModeIconMarkup(mode) {
    if (mode === "workspace-write") {
      return "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><path d='M3.1 12.9l2.9-.6 6-6-2.3-2.3-6 6z'></path><path d='M8.9 3.7l2.3 2.3'></path></svg>";
    }
    if (mode === "read-only") {
      return "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><path d='M1.8 8s2.3-3.6 6.2-3.6S14.2 8 14.2 8s-2.3 3.6-6.2 3.6S1.8 8 1.8 8z'></path><circle cx='8' cy='8' r='1.7'></circle></svg>";
    }
    if (mode === "full-access") {
      return "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><circle cx='8' cy='8' r='1.6'></circle><path d='M8 2.3v1.3'></path><path d='M8 12.4v1.3'></path><path d='M2.3 8h1.3'></path><path d='M12.4 8h1.3'></path><path d='M3.9 3.9l.9.9'></path><path d='M11.2 11.2l.9.9'></path><path d='M12.1 3.9l-.9.9'></path><path d='M4.8 11.2l-.9.9'></path></svg>";
    }
    return "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><path d='M8 1.6l4.6 1.8v3.7c0 3-1.7 5.4-4.6 7.2-2.9-1.8-4.6-4.2-4.6-7.2V3.4L8 1.6z'></path></svg>";
  }

  function commandExecModeLabel(mode) {
    if (mode === "none") {
      return "None";
    }
    if (mode === "ask-all") {
      return "Ask all";
    }
    if (mode === "ask-some" || mode === "ask") {
      return "Ask some";
    }
    if (mode === "all") {
      return "Ask none";
    }
    return "Ask some";
  }

  function normalizeCommandExecModeValue(mode) {
    var value = trim(String(mode || "")).toLowerCase();
    if (value === "ask") {
      return "ask-some";
    }
    if (value === "none" || value === "ask-all" || value === "ask-some" || value === "all") {
      return value;
    }
    return "";
  }

  function normalizePermissionModeValue(mode) {
    var value = trim(String(mode || "")).toLowerCase();
    if (value === "workspace-write" || value === "read-only" || value === "default" || value === "full-access") {
      return value;
    }
    return "";
  }

  function gitDeltaMarkup(added, deleted) {
    var addCount = Number(added || 0);
    var delCount = Number(deleted || 0);
    return "<span class='git-delta'><span class='git-add'>+" + addCount + "</span> <span class='git-del'>-" + delCount + "</span></span>";
  }

  function activeGitState() {
    return (
      state.gitByWorkspace[state.activeWorkspaceId] || {
        is_repo: false,
        branch: "",
        ahead: 0,
        behind: 0,
        added: 0,
        deleted: 0,
        changes: 0,
        staged_changes: 0,
        unstaged_changes: 0
      }
    );
  }

  function closeAllMenus(exceptId) {
    var ids = Object.keys(menuById);
    for (var i = 0; i < ids.length; i += 1) {
      var id = ids[i];
      if (exceptId && id === exceptId) {
        continue;
      }
      if (menuById[id]) {
        menuById[id].classList.add("hidden");
      }
    }

    if (el.modelStatusBtn) {
      el.modelStatusBtn.setAttribute("aria-expanded", "false");
    }
    if (el.openMenuBtn) {
      el.openMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.commitMenuBtn) {
      el.commitMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.branchMenuBtn) {
      el.branchMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.permissionsMenuBtn) {
      el.permissionsMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.modelPickerBtn) {
      el.modelPickerBtn.setAttribute("aria-expanded", "false");
    }
    if (el.runModeBtn) {
      el.runModeBtn.setAttribute("aria-expanded", "false");
    }
    if (el.themePickerBtn) {
      el.themePickerBtn.setAttribute("aria-expanded", "false");
    }
    if (el.reasoningMenuBtn) {
      el.reasoningMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.computeMenuBtn) {
      el.computeMenuBtn.setAttribute("aria-expanded", "false");
    }
    if (el.organizeBtn) {
      el.organizeBtn.setAttribute("aria-expanded", "false");
    }
    if (el.contextWindowBtn) {
      el.contextWindowBtn.setAttribute("aria-expanded", "false");
    }

    if (!exceptId && state.openWorkspaceMenuWorkspaceId) {
      state.openWorkspaceMenuWorkspaceId = "";
      renderWorkspaceTree();
    }
    if (!exceptId || exceptId !== "run-mode-menu") {
      state.runModeMoreExpanded = false;
    }
    if (!exceptId && state.openTriageSuppressProposalId) {
      state.openTriageSuppressProposalId = "";
    }
  }

  function toggleMenu(menuId, buttonEl) {
    var menu = menuById[menuId];
    if (!menu) {
      return;
    }

    var isOpen = !menu.classList.contains("hidden");
    closeAllMenus();

    if (isOpen) {
      return;
    }

    menu.classList.remove("hidden");
    if (buttonEl) {
      buttonEl.setAttribute("aria-expanded", "true");
    }
  }

  function openModal(modalEl) {
    if (!modalEl) {
      return;
    }
    modalEl.classList.remove("hidden");
  }

  function closeModal(modalEl) {
    if (!modalEl) {
      return;
    }
    modalEl.classList.add("hidden");
  }

  function closeAllModals() {
    closeModal(el.workspaceModal);
    closeModal(el.commitModal);
    closeModal(el.runActionModal);
    closeModal(el.settingsModal);
    closeModal(el.commandApprovalModal);
    closeModal(el.multi_agentModal);
  }

  function setWorkspaceDropActive(active) {
    if (active) {
      el.workspacePanel.classList.add("drop-active");
    } else {
      el.workspacePanel.classList.remove("drop-active");
    }
  }

  function setComposerDragActive(active) {
    if (!el.runForm) {
      return;
    }
    el.runForm.classList.toggle("drag-active", !!active);
  }

  function setBusy(value, workspaceId, conversationId) {
    state.busy = !!value;
    if (state.busy) {
      state.runningWorkspaceId = workspaceId || state.runningWorkspaceId || state.activeWorkspaceId || "";
      state.runningConversationId = conversationId || state.runningConversationId || state.activeConversationId || "";
      if (!liveRunTickTimer) {
        liveRunTickTimer = setInterval(function () {
          refreshRunningElapsedBadges();
        }, 1000);
      }
      if (!runReconcileTimer) {
        runReconcileTimer = setInterval(function () {
          reconcileRunningState();
        }, 2200);
      }
    } else {
      state.runningWorkspaceId = "";
      state.runningConversationId = "";
      if (runReconcileTimer) {
        clearInterval(runReconcileTimer);
        runReconcileTimer = null;
      }
      runReconcileBusy = false;
    }
  }

  function ensureSelection() {
    if (state.activeTriage) {
      state.activeWorkspaceId = "";
      state.activeConversationId = "";
      state.activeConversation = null;
      state.activeDraftWorkspaceId = "";
      return;
    }
    if (!state.workspaces.length) {
      state.activeWorkspaceId = "";
      state.activeConversationId = "";
      state.activeConversation = null;
      state.activeDraftWorkspaceId = "";
      return;
    }

    if (!getWorkspaceById(state.activeWorkspaceId)) {
      state.activeWorkspaceId = getSortedWorkspaces()[0].id;
      state.activeConversationId = "";
      state.activeConversation = null;
      state.activeDraftWorkspaceId = "";
    }

    if (state.activeWorkspaceId && typeof state.expandedWorkspaceIds[state.activeWorkspaceId] === "undefined") {
      state.expandedWorkspaceIds[state.activeWorkspaceId] = true;
    }

    if (state.activeConversationId) {
      var workspace = getWorkspaceById(state.activeWorkspaceId);
      if (!getConversationById(workspace, state.activeConversationId)) {
        state.activeConversationId = "";
        state.activeConversation = null;
      }
    }

    if (state.activeDraftWorkspaceId && !getWorkspaceById(state.activeDraftWorkspaceId)) {
      state.activeDraftWorkspaceId = "";
    }
  }

  function resolveWorkspaceFromRouteToken(token) {
    var raw = String(token || "");
    if (!raw) {
      return null;
    }
    var idHint = String(routeIdHint(raw) || "");
    for (var i = 0; i < state.workspaces.length; i += 1) {
      if (String(state.workspaces[i].id || "") === idHint) {
        return state.workspaces[i];
      }
    }
    var wantedSlug = slugifyRoutePart(raw);
    for (var j = 0; j < state.workspaces.length; j += 1) {
      if (slugifyRoutePart(state.workspaces[j].name || state.workspaces[j].id) === wantedSlug) {
        return state.workspaces[j];
      }
    }
    return null;
  }

  function resolveConversationFromRouteToken(workspace, token) {
    if (!workspace || !token || !Array.isArray(workspace.conversations)) {
      return null;
    }
    var raw = String(token || "");
    var idHint = String(routeIdHint(raw) || "");
    for (var i = 0; i < workspace.conversations.length; i += 1) {
      if (String(workspace.conversations[i].id || "") === idHint) {
        return workspace.conversations[i];
      }
    }
    var wantedSlug = slugifyRoutePart(raw);
    var match = null;
    var matchUpdated = 0;
    for (var j = 0; j < workspace.conversations.length; j += 1) {
      var conversation = workspace.conversations[j] || {};
      var slug = slugifyRoutePart(conversation.title || conversation.id);
      if (slug !== wantedSlug) {
        continue;
      }
      var updated = conversationUpdatedNumber(conversation);
      if (!match || updated > matchUpdated) {
        match = conversation;
        matchUpdated = updated;
      }
    }
    return match;
  }

  function applyRouteSelectionIfPending() {
    var requested = state.pendingRouteSelection;
    if (!requested || !requested.workspaceToken) {
      return;
    }
    state.pendingRouteSelection = null;
    var workspace = resolveWorkspaceFromRouteToken(requested.workspaceToken);
    if (!workspace) {
      return;
    }
    state.activeWorkspaceId = workspace.id;
    state.activeConversation = null;
    state.activeDraftWorkspaceId = "";
    state.expandedWorkspaceIds[workspace.id] = true;
    var conversation = resolveConversationFromRouteToken(workspace, requested.conversationToken || "");
    state.activeConversationId = conversation && conversation.id ? conversation.id : "";
  }

  function buildRoutePathForSelection() {
    var workspace = getWorkspaceById(state.activeWorkspaceId);
    if (!workspace) {
      return "/";
    }
    var workspaceToken = routeTokenFromLabelAndId(workspace.name || workspace.id, workspace.id);
    if (!workspaceToken) {
      return "/";
    }
    var parts = [encodeRoutePart(workspaceToken)];
    if (state.activeConversationId) {
      var conversation = getConversationById(workspace, state.activeConversationId);
      var conversationToken = routeTokenFromLabelAndId(
        (conversation && (conversation.title || conversation.id)) || state.activeConversationId,
        state.activeConversationId
      );
      if (conversationToken) {
        parts.push(encodeRoutePart(conversationToken));
      }
    }
    return "/" + parts.join("/") + "/";
  }

  function syncSelectionUrl(replace) {
    if (state.suppressSelectionUrlSync || typeof window === "undefined" || !window.history || !window.location) {
      return;
    }
    var nextPath = normalizeRoutePath(buildRoutePathForSelection());
    var currentPath = normalizeRoutePath(window.location.pathname || "/");
    if (nextPath === currentPath) {
      return;
    }
    var method = replace ? "replaceState" : "pushState";
    if (typeof window.history[method] !== "function") {
      return;
    }
    try {
      window.history[method]({}, "", nextPath);
    } catch (_err) {
      return;
    }
  }

  function navigateToRouteSelection() {
    var requested = parseRouteSelectionFromLocation();
    if (!requested || !requested.workspaceToken) {
      return Promise.resolve();
    }
    if (!state.workspaces.length) {
      state.pendingRouteSelection = requested;
      return Promise.resolve();
    }
    var workspace = resolveWorkspaceFromRouteToken(requested.workspaceToken);
    if (!workspace) {
      return Promise.resolve();
    }
    var conversation = resolveConversationFromRouteToken(workspace, requested.conversationToken || "");
    if (conversation && String(conversation.id || "") === String(state.activeConversationId || "") && String(workspace.id || "") === String(state.activeWorkspaceId || "")) {
      return Promise.resolve();
    }
    state.suppressSelectionUrlSync = true;
    var task = conversation && conversation.id
      ? selectConversation(workspace.id, conversation.id)
      : selectWorkspace(workspace.id);
    return task.finally(function () {
      state.suppressSelectionUrlSync = false;
    });
  }

  function newSelectionVersion() {
    state.selectionVersion += 1;
    return state.selectionVersion;
  }

  function isSelectionVersionCurrent(version) {
    return version === state.selectionVersion;
  }

  function isChatAtBottom() {
    if (!el.chatLog) {
      return true;
    }
    var remaining = el.chatLog.scrollHeight - el.chatLog.clientHeight - el.chatLog.scrollTop;
    return remaining <= 8;
  }

  function updateChatJumpButton() {
    if (!el.chatJumpBottomBtn) {
      return;
    }
    var shouldShow = !state.chatAutoScroll && !!state.activeConversationId;
    el.chatJumpBottomBtn.classList.toggle("show", shouldShow);
    el.chatJumpBottomBtn.classList.toggle("hidden", !shouldShow);
  }

  function jumpChatToBottom() {
    if (!el.chatLog) {
      return;
    }
    el.chatLog.scrollTop = el.chatLog.scrollHeight;
    state.chatAutoScroll = true;
    updateChatJumpButton();
  }

  function markArchiveConfirmReady(workspaceId, conversationId, key) {
    if (!workspaceId || !conversationId || !key) {
      return;
    }
    window.setTimeout(function () {
      if (state.pendingArchiveKey !== key) {
        return;
      }
      var selector = ".thread-confirm-btn[data-workspace-id='" + escAttr(workspaceId) + "'][data-conversation-id='" + escAttr(conversationId) + "']";
      var button = el.workspaceTree ? el.workspaceTree.querySelector(selector) : null;
      if (!button) {
        return;
      }
      button.disabled = false;
      button.classList.add("ready");
    }, 270);
  }

  function normalizedRunEventsList(list) {
    var items = Array.isArray(list) ? list : [];
    var normalized = [];
    for (var i = 0; i < items.length; i += 1) {
      var event = sanitizeRunEventForStorage(items[i]);
      if (event) {
        normalized.push(event);
      }
    }
    if (normalized.length > 22) {
      normalized = normalized.slice(normalized.length - 22);
    }
    return normalized;
  }

  function mergeConversationRunEvents(conversationId, remoteEvents) {
    var convId = String(conversationId || "");
    if (!convId) {
      return;
    }
    var remoteList = normalizedRunEventsList(remoteEvents);
    if (!remoteList.length) {
      return;
    }
    var hasRemoteRunning = false;
    for (var r = 0; r < remoteList.length; r += 1) {
      if (String((remoteList[r] && remoteList[r].status) || "") === "running") {
        hasRemoteRunning = true;
        break;
      }
    }
    var localList = normalizedRunEventsList(state.runEventsByConversation[convId]);
    var merged = [];
    var seen = {};

    function pushEvent(event) {
      if (!event) {
        return;
      }
      var key = String(event.id || "");
      if (key && seen[key]) {
        return;
      }
      if (key) {
        seen[key] = 1;
      }
      merged.push(event);
    }

    for (var i = 0; i < remoteList.length; i += 1) {
      pushEvent(remoteList[i]);
    }
    for (var j = 0; j < localList.length; j += 1) {
      var localEvent = localList[j] || {};
      var localStatus = String(localEvent.status || "");
      if (localStatus === "running" && hasRemoteRunning) {
        continue;
      }
      if (localStatus === "running" || localStatus === "approval_granted") {
        pushEvent(localEvent);
      }
    }

    if (merged.length > 22) {
      merged = merged.slice(merged.length - 22);
    }
    state.runEventsByConversation[convId] = merged;
    persistRunEventsSoon();
  }

  function runEventsForConversation(conversationId) {
    if (!conversationId) {
      return [];
    }
    return state.runEventsByConversation[conversationId] || [];
  }

  function outgoingKeyFor(workspaceId, conversationId, draftWorkspaceId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    var draftId = String(draftWorkspaceId || "");
    if (wsId && convId) {
      return "c:" + wsId + "::" + convId;
    }
    if (draftId) {
      return "d:" + draftId;
    }
    return "";
  }

  function activeOutgoingKey() {
    var draftWorkspaceId = state.activeDraftWorkspaceId;
    if (!draftWorkspaceId && state.activeWorkspaceId && !state.activeConversationId) {
      draftWorkspaceId = state.activeWorkspaceId;
    }
    return outgoingKeyFor(state.activeWorkspaceId, state.activeConversationId, draftWorkspaceId);
  }

  function pendingOutgoingList(key) {
    var safeKey = String(key || "");
    if (!safeKey) {
      return [];
    }
    var list = state.pendingOutgoingByKey[safeKey];
    return Array.isArray(list) ? list : [];
  }

  function addPendingOutgoing(key, text) {
    var safeKey = String(key || "");
    var content = trim(text || "");
    if (!safeKey || !content) {
      return "";
    }
    if (!Array.isArray(state.pendingOutgoingByKey[safeKey])) {
      state.pendingOutgoingByKey[safeKey] = [];
    }
    var id = "pending-" + String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000));
    state.pendingOutgoingByKey[safeKey].push({
      id: id,
      content: content,
      createdAt: Date.now()
    });
    return id;
  }

  function removePendingOutgoing(key, pendingId) {
    var safeKey = String(key || "");
    var id = String(pendingId || "");
    if (!safeKey || !id) {
      return;
    }
    var list = pendingOutgoingList(safeKey);
    if (!list.length) {
      return;
    }
    var kept = [];
    for (var i = 0; i < list.length; i += 1) {
      if (String(list[i].id || "") !== id) {
        kept.push(list[i]);
      }
    }
    if (kept.length) {
      state.pendingOutgoingByKey[safeKey] = kept;
    } else {
      delete state.pendingOutgoingByKey[safeKey];
    }
  }

  function movePendingOutgoing(oldKey, newKey, pendingId) {
    var fromKey = String(oldKey || "");
    var toKey = String(newKey || "");
    var id = String(pendingId || "");
    if (!fromKey || !toKey || !id || fromKey === toKey) {
      return;
    }
    var fromList = pendingOutgoingList(fromKey);
    if (!fromList.length) {
      return;
    }
    var entry = null;
    var kept = [];
    for (var i = 0; i < fromList.length; i += 1) {
      var item = fromList[i];
      if (!entry && String(item.id || "") === id) {
        entry = item;
      } else {
        kept.push(item);
      }
    }
    if (!entry) {
      return;
    }
    if (kept.length) {
      state.pendingOutgoingByKey[fromKey] = kept;
    } else {
      delete state.pendingOutgoingByKey[fromKey];
    }
    if (!Array.isArray(state.pendingOutgoingByKey[toKey])) {
      state.pendingOutgoingByKey[toKey] = [];
    }
    state.pendingOutgoingByKey[toKey].push(entry);
  }

  function consumePendingOutgoingByText(key, text) {
    var safeKey = String(key || "");
    var content = trim(text || "");
    if (!safeKey || !content) {
      return false;
    }
    var list = pendingOutgoingList(safeKey);
    if (!list.length) {
      return false;
    }
    var kept = [];
    var removed = false;
    for (var i = 0; i < list.length; i += 1) {
      var item = list[i];
      if (!removed && trim(item.content || "") === content) {
        removed = true;
      } else {
        kept.push(item);
      }
    }
    if (!removed) {
      return false;
    }
    if (kept.length) {
      state.pendingOutgoingByKey[safeKey] = kept;
    } else {
      delete state.pendingOutgoingByKey[safeKey];
    }
    return true;
  }

  function appendAssistantMessageOptimistic(workspaceId, conversationId, assistantText) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    var content = trim(assistantText || "");
    if (!wsId || !convId || !content) {
      return false;
    }
    if (
      !state.activeConversation ||
      String(state.activeWorkspaceId || "") !== wsId ||
      String(state.activeConversationId || "") !== convId
    ) {
      return false;
    }
    if (!Array.isArray(state.activeConversation.messages)) {
      state.activeConversation.messages = [];
    }
    var messages = state.activeConversation.messages;
    var last = messages.length ? messages[messages.length - 1] : null;
    if (last && String(last.role || "") === "assistant" && String(last.content || "") === content) {
      return false;
    }
    messages.push({ role: "assistant", content: content });
    cacheActiveConversationSnapshot(wsId, convId);
    return true;
  }

  function reconcilePendingOutgoingFromConversation(workspaceId, conversationId, conversation) {
    var key = outgoingKeyFor(workspaceId, conversationId, "");
    var pendingList = pendingOutgoingList(key);
    if (!pendingList.length) {
      return;
    }
    var messages = Array.isArray(conversation && conversation.messages) ? conversation.messages : [];
    var userCounts = {};
    for (var i = 0; i < messages.length; i += 1) {
      var msg = messages[i] || {};
      if (String(msg.role || "") !== "user") {
        continue;
      }
      var content = trim(msg.content || "");
      if (!content) {
        continue;
      }
      userCounts[content] = (userCounts[content] || 0) + 1;
    }
    var kept = [];
    for (var j = 0; j < pendingList.length; j += 1) {
      var pending = pendingList[j] || {};
      var pendingText = trim(pending.content || "");
      if (pendingText && userCounts[pendingText] > 0) {
        userCounts[pendingText] -= 1;
      } else {
        kept.push(pending);
      }
    }
    if (kept.length) {
      state.pendingOutgoingByKey[key] = kept;
    } else {
      delete state.pendingOutgoingByKey[key];
    }
  }

  function applyRunEventTerminalState(event, status, errorText, finishedAt) {
    if (!event) {
      return;
    }
    if (status === "error") {
      event.status = "error";
      if (!trim(errorText || "")) {
        event.error = trim(event.error || "Run did not complete.");
      } else {
        event.error = trim(errorText);
      }
    } else if (status === "cancelled") {
      event.status = "cancelled";
    } else if (status === "awaiting_approval") {
      event.status = "awaiting_approval";
    } else if (status === "awaiting_decision") {
      event.status = "awaiting_decision";
    } else {
      event.status = "done";
    }
    event.finished_at = finishedAt || new Date().toISOString();
    persistRunEventsSoon();
  }

  function finalizeLatestRunningEvent(conversationId, status, errorText) {
    var convId = String(conversationId || "");
    if (!convId) {
      return;
    }
    var events = state.runEventsByConversation[convId];
    if (!Array.isArray(events) || !events.length) {
      return;
    }
    var finishedAt = new Date().toISOString();
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") === "running") {
        applyRunEventTerminalState(events[i], status, errorText, finishedAt);
        return;
      }
    }
  }

  function finalizeAllRunningEvents(conversationId, status, errorText) {
    var convId = String(conversationId || "");
    if (!convId) {
      return;
    }
    var events = state.runEventsByConversation[convId];
    if (!Array.isArray(events) || !events.length) {
      return;
    }
    var finishedAt = new Date().toISOString();
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") !== "running") {
        continue;
      }
      applyRunEventTerminalState(events[i], status, errorText, finishedAt);
    }
  }

  function finalizeStaleRunningEventsForConversation(workspaceId, conversation) {
    if (!workspaceId || !conversation || !conversation.id) {
      return;
    }
    var pending = queueNumber(conversation.queue_pending);
    var running = String(conversation.queue_running || "0") === "1";
    if (running || pending > 0) {
      return;
    }
    var queueStatus = String(conversation.queue_last_status || "");
    if (!queueStatus) {
      if (conversationApprovalRequest(conversation) || isAwaitingApprovalConversation(workspaceId, conversation.id)) {
        queueStatus = "awaiting_approval";
      }
    }
    var eventStatus = "done";
    if (queueStatus === "error") {
      eventStatus = "error";
    } else if (queueStatus === "cancelled") {
      eventStatus = "cancelled";
    } else if (queueStatus === "awaiting_approval") {
      eventStatus = "awaiting_approval";
    } else if (queueStatus === "awaiting_decision") {
      eventStatus = "awaiting_decision";
    }
    finalizeAllRunningEvents(
      String(conversation.id || ""),
      eventStatus,
      eventStatus === "error" ? "Run did not complete." : ""
    );
  }

  function reconcileRunEventsFromQueueState() {
    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      if (!workspace || !Array.isArray(workspace.conversations)) {
        continue;
      }
      for (var j = 0; j < workspace.conversations.length; j += 1) {
        finalizeStaleRunningEventsForConversation(workspace.id, workspace.conversations[j]);
      }
    }
  }

  function hasAnyRunningRunEvent() {
    var keys = Object.keys(state.runEventsByConversation || {});
    for (var i = 0; i < keys.length; i += 1) {
      var events = state.runEventsByConversation[keys[i]];
      if (!Array.isArray(events) || !events.length) {
        continue;
      }
      for (var j = events.length - 1; j >= 0; j -= 1) {
        if (String(events[j].status || "") === "running") {
          return true;
        }
      }
    }
    return false;
  }

  function hasAnyQueuedOrRunningConversation() {
    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      var conversations = workspace && Array.isArray(workspace.conversations) ? workspace.conversations : [];
      for (var j = 0; j < conversations.length; j += 1) {
        var conversation = conversations[j] || {};
        if (String(conversation.queue_running || "0") === "1") {
          return true;
        }
        if (queueNumber(conversation.queue_pending) > 0) {
          return true;
        }
      }
    }
    return false;
  }

  function hasAnyQueuedOrRunningConversationInStateResponse(stateResponse) {
    if (!stateResponse || !stateResponse.success || !Array.isArray(stateResponse.workspaces)) {
      return false;
    }
    for (var i = 0; i < stateResponse.workspaces.length; i += 1) {
      var workspace = stateResponse.workspaces[i];
      var conversations = workspace && Array.isArray(workspace.conversations) ? workspace.conversations : [];
      for (var j = 0; j < conversations.length; j += 1) {
        var conversation = conversations[j] || {};
        if (String(conversation.queue_running || "0") === "1") {
          return true;
        }
        if (queueNumber(conversation.queue_pending) > 0) {
          return true;
        }
      }
    }
    return false;
  }

  function syncConversationQueueFromStateEntry(workspaceId, conversationId, conversationEntry) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    var entry = conversationEntry || null;
    if (!wsId || !convId || !entry) {
      return;
    }

    var pending = queueNumber(entry.queue_pending);
    var running = String(entry.queue_running || "0") === "1";
    var lastStatus = String(entry.queue_last_status || "");
    setConversationQueueFields(wsId, convId, {
      pending: pending,
      running: running,
      done: lastStatus === "done",
      lastStatus: lastStatus,
      firstId: String(entry.queue_first_id || ""),
      decisionRequest: typeof entry.decision_request === "undefined" ? undefined : entry.decision_request,
      approvalRequest: typeof entry.approval_request === "undefined" ? undefined : entry.approval_request
    });
    updateAwaitingApprovalFromQueueSnapshot(wsId, convId, {
      lastStatus: lastStatus,
      approvalRequest: entry.approval_request,
      pending: pending,
      running: running
    });
    finalizeStaleRunningEventsForConversation(wsId, entry);
  }

  function normalizedTerminalRunStatus(queueLastStatus) {
    var status = String(queueLastStatus || "");
    if (
      status !== "done" &&
      status !== "error" &&
      status !== "cancelled" &&
      status !== "awaiting_decision" &&
      status !== "awaiting_approval"
    ) {
      status = "done";
    }
    return status;
  }

  function healRunningEventsForConversationFromSummary(workspaceId, conversationId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return;
    }
    var workspace = getWorkspaceById(wsId);
    var conversation = getConversationById(workspace, convId);
    if (!conversation) {
      return;
    }

    finalizeStaleRunningEventsForConversation(wsId, conversation);

    var pending = queueNumber(conversation.queue_pending);
    var running = String(conversation.queue_running || "0") === "1";
    if (running || pending > 0) {
      return;
    }

    var events = runEventsForConversation(convId);
    var hasRunning = false;
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") === "running") {
        hasRunning = true;
        break;
      }
    }
    if (!hasRunning) {
      return;
    }

    var terminalStatus = normalizedTerminalRunStatus(conversation.queue_last_status);
    finalizeLatestRunningEvent(convId, terminalStatus, "");
    if (terminalStatus !== "awaiting_approval") {
      setAwaitingApprovalState(wsId, convId, false);
    }
    if (
      state.busy &&
      String(state.runningWorkspaceId || "") === wsId &&
      String(state.runningConversationId || "") === convId
    ) {
      setBusy(false);
    }
  }

  function reconcileRunningState() {
    var shouldReconcile = state.busy || hasAnyRunningRunEvent();
    if (!shouldReconcile || runReconcileBusy) {
      return;
    }
    var workspaceId = String(state.runningWorkspaceId || "");
    var conversationId = String(state.runningConversationId || "");
    runReconcileBusy = true;
    loadState({ timeoutMs: 6000 })
      .then(function () {
        reconcileRunEventsFromQueueState();
        var hasQueuedOrRunning = hasAnyQueuedOrRunningConversation();
        if (state.busy && !hasQueuedOrRunning) {
          setBusy(false);
        }
        if (!state.busy && hasQueuedOrRunning) {
          state.queueWorkerActive = false;
          kickQueueWorker();
        }

        if (!workspaceId || !conversationId) {
          if (state.activeWorkspaceId && state.activeConversationId) {
            loadConversation({ timeoutMs: 6000 }).catch(function () {
              return null;
            });
          }
          return null;
        }

        var gitRefresh = Promise.resolve();
        if (state.activeWorkspaceId === workspaceId) {
          gitRefresh = refreshGitStatus().catch(function () {
            return null;
          });
        }
        return gitRefresh.then(function () {
          var ws = getWorkspaceById(workspaceId);
          var conv = getConversationById(ws, conversationId);
          var stillRunning = !!(conv && String(conv.queue_running || "0") === "1");
          var pending = conv ? queueNumber(conv.queue_pending) : 0;
          if (stillRunning || pending > 0) {
            return;
          }
          setBusy(false);
          finalizeLatestRunningEvent(conversationId, "done", "");
          if (state.activeWorkspaceId === workspaceId && state.activeConversationId === conversationId) {
            loadConversation({ timeoutMs: 6000 }).catch(function () {
              return null;
            });
          }
          return null;
        });
      })
      .catch(function () {
        return null;
      })
      .finally(function () {
        runReconcileBusy = false;
        renderUi();
      });
  }

  function startRunEventHealLoop() {
    if (runEventHealTimer) {
      clearInterval(runEventHealTimer);
      runEventHealTimer = null;
    }
    runEventHealTimer = setInterval(function () {
      if (runEventHealBusy) {
        if (runEventHealBusySince > 0 && Date.now() - runEventHealBusySince > 12000) {
          runEventHealBusy = false;
          runEventHealBusySince = 0;
          renderUi();
        }
        return;
      }
      var domShowsRunning = !!(el.chatLog && el.chatLog.querySelector(".run-line.running"));
      if (!state.busy && !hasAnyRunningRunEvent() && !domShowsRunning) {
        return;
      }
      runEventHealBusy = true;
      runEventHealBusySince = Date.now();
      if (runEventHealGuardTimer) {
        clearTimeout(runEventHealGuardTimer);
        runEventHealGuardTimer = null;
      }
      runEventHealGuardTimer = setTimeout(function () {
        if (!runEventHealBusy) {
          runEventHealGuardTimer = null;
          return;
        }
        runEventHealBusy = false;
        runEventHealBusySince = 0;
        runEventHealGuardTimer = null;
        renderUi();
      }, 12500);
      var watchedWorkspaceId = String(state.runningWorkspaceId || state.activeWorkspaceId || "");
      var watchedConversationId = String(state.runningConversationId || state.activeConversationId || "");
      loadState({ timeoutMs: 6000 })
        .then(function () {
          reconcileRunEventsFromQueueState();

          var hasQueuedOrRunning = hasAnyQueuedOrRunningConversation();
          if (state.busy && !hasQueuedOrRunning) {
            setBusy(false);
          }
          if (!state.busy && findNextQueuedConversation()) {
            state.queueWorkerActive = false;
            kickQueueWorker();
          }

          if (state.activeWorkspaceId && state.activeConversationId) {
            loadConversation({ timeoutMs: 6000 }).catch(function () {
              return null;
            });
          }
          return null;
        })
        .catch(function () {
          return apiGet("state", {}, { timeoutMs: 9000 })
            .then(function (response) {
              if (!response || !response.success) {
                return null;
              }
              var hasQueuedOrRunning = hasAnyQueuedOrRunningConversationInStateResponse(response);
              var entry = findConversationStateEntry(response, watchedWorkspaceId, watchedConversationId);
              if (entry && watchedWorkspaceId && watchedConversationId) {
                syncConversationQueueFromStateEntry(watchedWorkspaceId, watchedConversationId, entry);
              } else if (!hasQueuedOrRunning && watchedConversationId) {
                finalizeLatestRunningEvent(watchedConversationId, "done", "");
              }

              if (state.busy && !hasQueuedOrRunning) {
                setBusy(false);
              }

              if (
                !state.busy &&
                entry &&
                queueNumber(entry.queue_pending) > 0 &&
                String(entry.queue_running || "0") !== "1"
              ) {
                state.queueWorkerActive = false;
                kickQueueWorker();
              }

              if (state.activeWorkspaceId && state.activeConversationId) {
                loadConversation({ timeoutMs: 6000 }).catch(function () {
                  return null;
                });
              }
              return null;
            })
            .catch(function () {
              return null;
            });
        })
        .finally(function () {
          runEventHealBusy = false;
          runEventHealBusySince = 0;
          if (runEventHealGuardTimer) {
            clearTimeout(runEventHealGuardTimer);
            runEventHealGuardTimer = null;
          }
          renderUi();
        });
    }, 1800);
  }

  function stopRunEventHealLoop() {
    if (runEventHealTimer) {
      clearInterval(runEventHealTimer);
      runEventHealTimer = null;
    }
    runEventHealBusy = false;
    runEventHealBusySince = 0;
    if (runEventHealGuardTimer) {
      clearTimeout(runEventHealGuardTimer);
      runEventHealGuardTimer = null;
    }
  }

  function persistRunEventsSoon() {
    if (runEventsSaveTimer) {
      return;
    }
    runEventsSaveTimer = setTimeout(function () {
      runEventsSaveTimer = null;
      saveRunEventsState(state.runEventsByConversation);
    }, 240);
  }

  function pruneRunEventsByKnownConversations() {
    var known = {};
    for (var i = 0; i < state.workspaces.length; i += 1) {
      var workspace = state.workspaces[i];
      var conversations = workspace && Array.isArray(workspace.conversations) ? workspace.conversations : [];
      for (var j = 0; j < conversations.length; j += 1) {
        var conversation = conversations[j] || {};
        if (conversation.id) {
          known[String(conversation.id)] = true;
        }
      }
    }
    var changed = false;
    var keys = Object.keys(state.runEventsByConversation || {});
    for (var k = 0; k < keys.length; k += 1) {
      var key = String(keys[k] || "");
      if (!known[key]) {
        delete state.runEventsByConversation[key];
        changed = true;
      }
    }
    if (changed) {
      persistRunEventsSoon();
    }
  }

  function pushRunEvent(conversationId, eventData) {
    if (!conversationId) {
      return null;
    }

    if (!state.runEventsByConversation[conversationId]) {
      state.runEventsByConversation[conversationId] = [];
    }

    var event = eventData || {};
    if (!event.id) {
      event.id = String(Date.now()) + "-" + String(Math.floor(Math.random() * 999999));
    }

    state.runEventsByConversation[conversationId].push(event);
    if (state.runEventsByConversation[conversationId].length > 22) {
      state.runEventsByConversation[conversationId].shift();
    }
    persistRunEventsSoon();

    return event;
  }

  function formatRunCommands(commands) {
    if (!commands || commands.length === 0) {
      return "<p class='empty-state'>No commands were proposed or executed.</p>";
    }

    var html = "";
    for (var i = 0; i < commands.length; i += 1) {
      var item = commands[i] || {};
      var status = item.status || "unknown";
      html += "<div class='run-command'>";
      html += "<div class='run-command-head'><code>" + escHtml(item.command || "") + "</code><span class='badge " + escHtml(status) + "'>" + escHtml(status) + "</span></div>";
      html += "<pre class='run-code-block run-command-output'>" + escHtml(item.output || "") + "</pre>";
      html += "</div>";
    }
    return html;
  }

  function runTraceAttemptCount(event) {
    var combined = trim(String((event && event.failures) || "")) + "\n" + trim(String((event && event.session_log) || ""));
    if (!trim(combined)) {
      return 0;
    }
    var matches = combined.match(/^##\s+/gm);
    return matches ? matches.length : 0;
  }

  function runDetailsShouldBeOpen(eventId) {
    var key = String(eventId || "");
    if (!key) {
      return false;
    }
    return !!state.runDetailsOpenByEventId[key];
  }

  function formatDurationLabel(totalSeconds) {
    var seconds = Number(totalSeconds || 0);
    if (!isFinite(seconds) || seconds < 0) {
      seconds = 0;
    }
    seconds = Math.floor(seconds);
    var hours = Math.floor(seconds / 3600);
    var minutes = Math.floor((seconds % 3600) / 60);
    var remaining = seconds % 60;
    if (hours > 0) {
      return String(hours) + "h " + String(minutes) + "m " + String(remaining) + "s";
    }
    if (minutes > 0) {
      return String(minutes) + "m " + String(remaining) + "s";
    }
    return String(remaining) + "s";
  }

  function thoughtDurationLabel(startedAt, finishedAt) {
    var startedMs = Date.parse(startedAt || "");
    var endedMs = Date.parse(finishedAt || "");
    if (!isFinite(startedMs) || startedMs <= 0) {
      return "";
    }
    if (!isFinite(endedMs) || endedMs <= 0 || endedMs < startedMs) {
      endedMs = Date.now();
    }
    var totalSeconds = Math.max(0, Math.floor((endedMs - startedMs) / 1000));
    return formatDurationLabel(totalSeconds);
  }

  function runTraceSummaryLabel(event, isRunning) {
    var duration = thoughtDurationLabel(event && event.started_at, isRunning ? "" : (event && event.finished_at));
    if (isRunning) {
      return "Working for " + (duration || "0s");
    }
    if (duration) {
      return "Worked for " + duration;
    }
    return "Worked";
  }

  function decodeMaybeUriText(rawText) {
    var raw = String(rawText || "");
    if (!/%[0-9a-fA-F]{2}/.test(raw)) {
      return raw;
    }
    var plusEscaped = raw.replace(/\+/g, "%20");
    try {
      return decodeURIComponent(plusEscaped);
    } catch (_err) {
      return plusEscaped
        .replace(/%0D%0A/gi, "\n")
        .replace(/%0A/gi, "\n")
        .replace(/%09/gi, "\t")
        .replace(/%20/gi, " ")
        .replace(/%3A/gi, ":")
        .replace(/%2F/gi, "/")
        .replace(/%2D/gi, "-")
        .replace(/%5B/gi, "[")
        .replace(/%5D/gi, "]");
    }
  }

  function normalizeRunNarrativeText(rawText) {
    var text = String(decodeMaybeUriText(rawText) || "");
    if (!trim(text)) {
      return "";
    }
    text = text.replace(/\r\n?/g, "\n");
    text = text.replace(/\u0000/g, "");
    text = text.replace(/(\])(?=\[\d{2}:\d{2}:\d{2}\])/g, "$1\n");
    text = text.replace(/([.?!])\s*(\[\d{2}:\d{2}:\d{2}\])/g, "$1\n$2");
    text = text.replace(/\s*(MODE_UPDATE|COMMANDS|CONTRACT|PATCH|DONE_CLAIM|PLAN_UPDATE|CHECKPOINT|DECISION_REQUEST|FINAL):\s*/g, "\n$1: ");
    text = text.replace(/\s*(\*\*[^*\n]{3,}\*\*)\s*/g, "\n$1 ");
    text = text.replace(/\s*(###\s+[^\n]+)\s*/g, "\n$1\n");
    text = text.replace(/\s*(User request:|Latest user request:|Conversation context:|Workspace snapshot:|Failure ledger \(tail\):|Session log \(tail\):|Assumptions ledger \(tail\):|Previous iteration feedback:|Mode objective:|Mode constraints:|Current plan:|Rules:|Return ONLY these sections exactly:|Typed state:|Current mode:)\s*/g, "\n$1 ");
    text = text.replace(/\n{3,}/g, "\n\n");
    return trim(text);
  }

  function splitLongNarrativePart(text, maxLength) {
    var part = trim(text || "");
    var limit = Number(maxLength || 220);
    if (!part) {
      return [];
    }
    if (!isFinite(limit) || limit < 80) {
      limit = 220;
    }
    var pieces = [];
    var remaining = part;
    while (remaining.length > limit) {
      var breakAt = remaining.lastIndexOf(" ", limit);
      if (breakAt < Math.floor(limit * 0.5)) {
        breakAt = limit;
      }
      pieces.push(trim(remaining.slice(0, breakAt)));
      remaining = trim(remaining.slice(breakAt));
    }
    if (remaining) {
      pieces.push(remaining);
    }
    return pieces;
  }

  function splitNarrativeFragments(lineText) {
    var line = String(lineText || "");
    if (!trim(line)) {
      return [];
    }
    line = line.replace(/([.!?])\s+(?=[A-Z0-9\[])/g, "$1\n");
    line = line.replace(/\s*(Goal:|Subgoals:|Constraints:|Unknowns:|Next Action:|Completion Criteria:|Transition:|Reason:|Checkpoint:|Command:|Status:|Output:|Question:|Options:|Input:|Assumption:|Action:|Error:|Hypothesis:|Current mode:)\s*/g, "\n$1 ");
    line = line.replace(/\n{2,}/g, "\n");
    var coarseParts = line.split(/\n+/);
    var parts = [];
    for (var i = 0; i < coarseParts.length; i += 1) {
      var coarse = trim(coarseParts[i] || "");
      if (!coarse) {
        continue;
      }
      var longParts = splitLongNarrativePart(coarse, 220);
      for (var j = 0; j < longParts.length; j += 1) {
        var item = trim(longParts[j] || "");
        if (item) {
          parts.push(item);
        }
      }
    }
    return parts;
  }

  function splitRunStreamEntries(streamText) {
    var normalized = normalizeRunNarrativeText(streamText);
    if (!normalized) {
      return [];
    }
    var entries = [];
    var stampRegex = /\[(\d{2}:\d{2}:\d{2})\]\s*/g;
    var match = null;
    var foundStamp = false;
    var activeStamp = "";
    var activeStart = 0;

    function pushChunk(stamp, chunkText) {
      var chunk = trim(String(chunkText || ""));
      if (!chunk) {
        return;
      }
      var lines = chunk.split(/\n+/);
      for (var i = 0; i < lines.length; i += 1) {
        var lineParts = splitNarrativeFragments(lines[i] || "");
        for (var j = 0; j < lineParts.length; j += 1) {
          entries.push({
            time: stamp,
            text: lineParts[j]
          });
        }
      }
    }

    while ((match = stampRegex.exec(normalized)) !== null) {
      foundStamp = true;
      if (activeStamp) {
        pushChunk(activeStamp, normalized.slice(activeStart, match.index));
      } else {
        pushChunk("", normalized.slice(0, match.index));
      }
      activeStamp = String(match[1] || "");
      activeStart = stampRegex.lastIndex;
    }

    if (foundStamp) {
      pushChunk(activeStamp, normalized.slice(activeStart));
      return entries;
    }

    var fallbackLines = normalized.split(/\n+/);
    for (var k = 0; k < fallbackLines.length; k += 1) {
      var fallbackParts = splitNarrativeFragments(fallbackLines[k] || "");
      for (var n = 0; n < fallbackParts.length; n += 1) {
        entries.push({
          time: "",
          text: fallbackParts[n]
        });
      }
    }
    return entries;
  }

  function runStepTone(text) {
    var lower = String(text || "").toLowerCase();
    if (!lower) {
      return "info";
    }
    if (/(fatal|failed|error|denied|blocked|mismatch)/.test(lower)) {
      return "error";
    }
    if (/(warning|retry|fallback|recovered)/.test(lower)) {
      return "warn";
    }
    if (/(run finalized|done|completed|success|verified|pass)/.test(lower)) {
      return "success";
    }
    if (/(current mode|mode_update|transition)/.test(lower)) {
      return "mode";
    }
    if (/(iteration\s+\d+\s+started|requesting model output|starting|compacted)/.test(lower)) {
      return "progress";
    }
    return "info";
  }

  function formatRunStreamFeed(event, isRunning) {
    var entries = splitRunStreamEntries(event && event.stream_text);
    var maxEntries = isRunning ? 220 : 320;
    var clippedCount = 0;
    if (entries.length > maxEntries) {
      clippedCount = entries.length - maxEntries;
      entries = entries.slice(clippedCount);
    }
    var html = "<div class='run-live-feed'>";
    if (!entries.length) {
      html += "<p class='run-line subtle'>" + (isRunning ? "Waiting for trace output..." : "No step timeline captured for this run.") + "</p>";
      html += "</div>";
      return html;
    }
    if (clippedCount > 0) {
      html += "<p class='run-feed-clip'>Showing latest " + escHtml(String(entries.length)) + " steps (" + escHtml(String(clippedCount)) + " earlier steps hidden).</p>";
    }
    for (var i = 0; i < entries.length; i += 1) {
      var entry = entries[i] || {};
      var tone = runStepTone(entry.text);
      html += "<div class='run-step " + escHtml(tone) + "'>";
      html += "<span class='run-step-time'>" + escHtml(entry.time || "step") + "</span>";
      html += "<span class='run-step-text'>" + escHtml(entry.text || "") + "</span>";
      html += "</div>";
    }
    html += "</div>";
    return html;
  }

  function formatRunNarrativeSection(title, rawText) {
    var text = normalizeRunNarrativeText(rawText);
    if (!text) {
      return "";
    }
    var paragraphs = text.split(/\n{2,}/);
    var body = "";
    for (var i = 0; i < paragraphs.length; i += 1) {
      var paragraph = trim(paragraphs[i] || "");
      if (!paragraph) {
        continue;
      }
      body += "<p>" + escHtml(paragraph).replace(/\n/g, "<br>") + "</p>";
    }
    if (!body) {
      return "";
    }
    return "<div class='run-trace-block'><p class='run-trace-title'>" + escHtml(title) + "</p><div class='run-prose'>" + body + "</div></div>";
  }

  function summarizeRunChanges(event) {
    var summary = {
      added: 0,
      deleted: 0,
      files: [],
      hasDiff: false
    };
    var fileMap = {};
    var diffText = String((event && event.git_diff) || "");
    var statusText = String((event && event.git_status) || "");
    if (trim(diffText)) {
      summary.hasDiff = true;
      var diffLines = diffText.split(/\r?\n/);
      for (var i = 0; i < diffLines.length; i += 1) {
        var line = diffLines[i] || "";
        var diffMatch = line.match(/^diff --git a\/(.+?) b\/(.+)$/);
        if (diffMatch) {
          var diffPath = trim(diffMatch[2] || diffMatch[1] || "");
          if (diffPath && !fileMap[diffPath]) {
            fileMap[diffPath] = true;
            summary.files.push(diffPath);
          }
          continue;
        }
        if (/^\+/.test(line) && !/^\+\+\+/.test(line)) {
          summary.added += 1;
        } else if (/^-/.test(line) && !/^---/.test(line)) {
          summary.deleted += 1;
        }
      }
    }
    if (!summary.files.length && trim(statusText)) {
      var statusLines = statusText.split(/\r?\n/);
      for (var j = 0; j < statusLines.length; j += 1) {
        var statusLine = trim(statusLines[j] || "");
        if (!statusLine) {
          continue;
        }
        var statusMatch = statusLine.match(/^[ MARCUD\?]{1,2}\s+(.+)$/);
        if (!statusMatch) {
          continue;
        }
        var statusPath = trim(statusMatch[1] || "");
        var arrow = statusPath.indexOf("->");
        if (arrow >= 0) {
          statusPath = trim(statusPath.slice(arrow + 2));
        }
        if (statusPath.charAt(0) === '"' && statusPath.charAt(statusPath.length - 1) === '"') {
          statusPath = statusPath.slice(1, -1);
        }
        if (!statusPath || fileMap[statusPath]) {
          continue;
        }
        fileMap[statusPath] = true;
        summary.files.push(statusPath);
      }
    }
    return summary;
  }

  function formatRunChangesCard(event) {
    var summary = summarizeRunChanges(event);
    if (!summary.files.length && summary.added === 0 && summary.deleted === 0) {
      return "";
    }
    var fileCount = summary.files.length;
    var html = "<div class='run-changes-card'>";
    html += "<p class='run-changes-head'>" + escHtml(String(fileCount)) + " file" + (fileCount === 1 ? "" : "s") + " changed";
    html += " <span class='run-delta add'>+" + escHtml(String(summary.added)) + "</span>";
    html += " <span class='run-delta del'>-" + escHtml(String(summary.deleted)) + "</span>";
    html += "</p>";
    if (fileCount > 0) {
      html += "<div class='run-changes-list'>";
      var shown = Math.min(6, fileCount);
      for (var i = 0; i < shown; i += 1) {
        html += "<code>" + escHtml(summary.files[i] || "") + "</code>";
      }
      if (fileCount > shown) {
        html += "<p class='run-line subtle'>+" + escHtml(String(fileCount - shown)) + " more files</p>";
      }
      html += "</div>";
    }
    html += "</div>";
    return html;
  }

  function formatRunAdvancedTrace(event) {
    var sections = "";
    if (trim(event && event.state)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Mode State</p><pre class='run-code-block'>" + escHtml(event.state || "") + "</pre></div>";
    }
    if (trim(event && event.failures)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Failure Ledger</p><pre class='run-code-block'>" + escHtml(event.failures || "") + "</pre></div>";
    }
    if (trim(event && event.session_log)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Session Log</p><pre class='run-code-block'>" + escHtml(event.session_log || "") + "</pre></div>";
    }
    if (trim(event && event.git_status)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Git Status</p><pre class='run-code-block'>" + escHtml(event.git_status || "") + "</pre></div>";
    }
    if (trim(event && event.git_diff)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Git Diff</p><div class='diff-view run-diff-view'>" + formatDiff(event.git_diff || "") + "</div></div>";
    }
    if (!sections) {
      return "";
    }
    return "<details class='run-details run-advanced'><summary><span class='run-summary-label'>Advanced run diagnostics</span></summary>" + sections + "</details>";
  }

  function runEventHasTraceData(event) {
    if (!event) {
      return false;
    }
    if (trim(event.stream_text || "")) {
      return true;
    }
    if (trim(event.plan || "")) {
      return true;
    }
    if (event.commands && event.commands.length) {
      return true;
    }
    if (trim(event.state || "")) {
      return true;
    }
    if (trim(event.failures || "")) {
      return true;
    }
    if (trim(event.session_log || "")) {
      return true;
    }
    if (trim(event.git_status || "")) {
      return true;
    }
    return trim(event.git_diff || "") !== "";
  }

  function formatRunTrace(event, options) {
    if (!event) {
      return "";
    }
    var opts = options || {};
    var isRunning = !!opts.isRunning;
    var sections = "";
    sections += "<div class='run-trace-block run-trace-stream'><p class='run-trace-title'>" + (isRunning ? "Live steps" : "Step timeline") + "</p>" + formatRunStreamFeed(event, isRunning) + "</div>";
    sections += formatRunNarrativeSection("Plan", event.plan || "");
    if (event.commands && event.commands.length) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Command runs</p>" + formatRunCommands(event.commands || []) + "</div>";
    }
    var advanced = formatRunAdvancedTrace(event);
    if (advanced) {
      sections += advanced;
    }
    if (!sections || (!isRunning && !runEventHasTraceData(event) && !thoughtDurationLabel(event && event.started_at, event && event.finished_at))) {
      return "";
    }
    var eventId = String(event.id || "");
    var hasSeenToggle = Object.prototype.hasOwnProperty.call(state.runDetailsOpenByEventId, eventId);
    var isOpen = hasSeenToggle ? runDetailsShouldBeOpen(eventId) : !!opts.defaultOpen;
    var openAttr = isOpen ? " open" : "";
    var startedAttr = isRunning ? " data-started-at='" + escAttr(event.started_at || "") + "'" : "";
    var detailsClass = "run-details " + (isRunning ? "run-thinking" : "run-rollup");
    var summaryLabel = runTraceSummaryLabel(event, isRunning);
    var summaryInner = "";
    if (isRunning) {
      summaryInner = "<span class='run-summary-label meta-glimmer'>" + escHtml(summaryLabel) + "</span>";
    } else {
      summaryInner = "<span class='run-rollup-line' aria-hidden='true'></span><span class='run-summary-label'>" + escHtml(summaryLabel) + "</span><span class='run-rollup-line' aria-hidden='true'></span>";
    }
    return "<details class='" + detailsClass + "' data-event-id='" + escAttr(eventId) + "'" + openAttr + startedAttr + "><summary>" + summaryInner + "</summary>" + sections + "</details>";
  }

  function friendlyRunErrorText(event) {
    var attempts = runTraceAttemptCount(event);
    var base = attempts > 0
      ? "I couldn't complete that run after " + attempts + " attempt" + (attempts === 1 ? "" : "s") + "."
      : "I couldn't complete that run.";
    var raw = String((event && event.error) || "").toLowerCase();
    if (raw.indexOf("approval") >= 0 || raw.indexOf("blocked") >= 0 || raw.indexOf("denied") >= 0) {
      return base + " A command needed approval.";
    }
    if (trim(event && event.error)) {
      return base + " " + String(event.error || "");
    }
    return base + " Please retry.";
  }

  function assistantLooksLikeTrace(text) {
    var raw = String(text || "");
    if (!trim(raw)) {
      return false;
    }
    var hasAttemptHeaders = /^##\s+\d{4}-\d{2}-\d{2}T/m.test(raw);
    var hasTraceMarkers = /(Action:|Hypothesis:|Next Attempt:|approval_required|Tool call failed|Refine command set)/i.test(raw);
    if (hasAttemptHeaders && hasTraceMarkers) {
      return true;
    }
    if (hasAttemptHeaders) {
      return true;
    }
    var hasControlScaffold = /(MODE_UPDATE:|PLAN_UPDATE:|DONE_CLAIM:|Transition:\s+[A-Z]+\s*->\s*[A-Z]+|Checkpoint:|final action plan|Next Action:\s*Completion Criteria:)/i.test(raw);
    var hasAgentModeMarkers = /(INVESTIGATE|DESIGN|IMPLEMENT|VERIFY|DONE)/i.test(raw);
    return hasControlScaffold && hasAgentModeMarkers;
  }

  function renderRunEvent(event, workspaceId, conversationId) {
    if (!event) {
      return "";
    }

    var status = event.status || "done";
    var decisionHint = trim(String(event.decision_hint || ""));
    var runClass = "msg run " + escHtml(status);
    var html = "";

    if (status === "running") {
      html = "<article class='" + runClass + "'>";
      var startedAt = Date.parse(event.started_at || "");
      var elapsed = 0;
      if (isFinite(startedAt) && startedAt > 0) {
        elapsed = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
      }
      html += "<p class='run-line running' data-started-at='" + escAttr(event.started_at || "") + "'><span class='run-spinner' aria-hidden='true'></span> <span class='meta-glimmer'>Thinking</span>";
      html += " <span class='run-elapsed'>" + (elapsed > 0 ? elapsed + "s" : "") + "</span>";
      if (workspaceId && conversationId) {
        html += "<button type='button' class='run-stop-btn' aria-label='Stop run' title='Stop run' data-action='stop-run' data-workspace-id='" + escAttr(workspaceId) + "' data-conversation-id='" + escAttr(conversationId) + "'><span class='run-stop-square' aria-hidden='true'>&#9632;</span></button>";
      }
      html += "</p>";
      html += formatRunTrace(event, { isRunning: true, defaultOpen: true });
      html += "</article>";
      return html;
    }

    if (status === "cancelled") {
      html = "<article class='" + runClass + "'>";
      html += "<p class='run-line subtle'>Run stopped.</p>";
      html += formatRunTrace(event, { defaultOpen: false });
      html += "</article>";
      return html;
    }

    if (status === "approval_granted") {
      runClass += " run-narrative run-approval-note";
      html = "<article class='" + runClass + "'>";
      var approvedScope = String(event.approved_scope || "once");
      var approvedCommand = trim(String(event.approved_command || ""));
      var approvalText = approvedScope === "remember"
        ? "Execution approved and remembered."
        : "Execution approved once.";
      if (approvedCommand) {
        approvalText += " " + approvedCommand;
      }
      html += "<p class='run-line subtle'>" + escHtml(approvalText) + "</p>";
      if (decisionHint && !/one-time rule/i.test(decisionHint)) {
        html += "<p class='run-line subtle run-decision-hint'>Matched by: " + escHtml(decisionHint) + "</p>";
      }
      html += "</article>";
      return html;
    }

    if (status === "error") {
      html = "<article class='" + runClass + "'>";
      html += "<p class='run-line error'>" + escHtml(friendlyRunErrorText(event)) + "</p>";
      html += formatRunTrace(event, { defaultOpen: true });
      html += formatRunChangesCard(event);
      html += "</article>";
      return html;
    }
    if (status === "awaiting_approval") {
      runClass += " run-narrative";
      html = "<article class='" + runClass + "'>";
      html += "<p class='run-line subtle'>Awaiting command approval.</p>";
      html += formatRunTrace(event, { defaultOpen: true });
      html += "</article>";
      return html;
    }
    if (status === "awaiting_decision") {
      runClass += " run-narrative";
      html = "<article class='" + runClass + "'>";
      html += "<p class='run-line subtle'>Awaiting your decision.</p>";
      html += formatRunTrace(event, { defaultOpen: true });
      html += "</article>";
      return html;
    }

    var runModelText = "";
    if (event.model) {
      var runModelParts = parseModelDisplay(event.model);
      runModelText = runModelParts.primary;
      if (runModelParts.meta) {
        runModelText += " (" + runModelParts.meta + ")";
      }
    }
    var conversation = null;
    if (workspaceId && conversationId) {
      conversation = getConversationById(getWorkspaceById(workspaceId), conversationId);
    }
    var queuePending = queueNumber(conversation && conversation.queue_pending);
    var queueRunning = !!(conversation && String(conversation.queue_running || "0") === "1");
    var queueLastStatus = String(conversation && conversation.queue_last_status || "");
    var queueAwaitingApproval = (
      queueLastStatus === "awaiting_approval" ||
      isAwaitingApprovalConversation(workspaceId, conversationId) ||
      !!conversationApprovalRequest(conversation)
    );
    var queueAwaitingDecision = queueLastStatus === "awaiting_decision" || !!normalizeDecisionRequest(conversation && conversation.decision_request);
    html = "<article class='" + runClass + "'>";
    if (queueRunning || queuePending > 0) {
      html = "<article class='" + runClass + " run-narrative'>";
      html += "<p class='run-line subtle'>Run step complete. Continuing...</p>";
    } else if (queueAwaitingApproval) {
      html = "<article class='" + runClass + " run-narrative'>";
      html += "<p class='run-line subtle'>Run paused. Awaiting command approval.</p>";
    } else if (queueAwaitingDecision) {
      html = "<article class='" + runClass + " run-narrative'>";
      html += "<p class='run-line subtle'>Run paused. Awaiting your decision.</p>";
    } else if (runModelText) {
      html += "<p class='run-line subtle'>Model: " + escHtml(runModelText) + "</p>";
    }
    html += formatRunTrace(event, { defaultOpen: false });
    if (!queueRunning && queuePending < 1 && !queueAwaitingApproval && !queueAwaitingDecision) {
      html += formatRunChangesCard(event);
    }
    html += "</article>";
    return html;
  }

  function findLatestRunEventByStatus(conversationId, statuses) {
    var convId = String(conversationId || "");
    var wanted = Array.isArray(statuses) ? statuses : [];
    if (!convId || !wanted.length) {
      return null;
    }
    var events = state.runEventsByConversation[convId];
    if (!Array.isArray(events) || !events.length) {
      return null;
    }
    for (var i = events.length - 1; i >= 0; i -= 1) {
      var event = events[i] || {};
      var status = String(event.status || "");
      for (var j = 0; j < wanted.length; j += 1) {
        if (status === String(wanted[j] || "")) {
          return event;
        }
      }
    }
    return null;
  }

  function refreshRunningElapsedBadges() {
    if (!el.chatLog) {
      return;
    }
    var lines = el.chatLog.querySelectorAll(".run-line.running[data-started-at]");
    if (!lines || !lines.length) {
      return;
    }
    var nowMs = Date.now();
    for (var i = 0; i < lines.length; i += 1) {
      var line = lines[i];
      var startedRaw = line.getAttribute("data-started-at") || "";
      var startedMs = Date.parse(startedRaw);
      if (!isFinite(startedMs) || startedMs <= 0) {
        continue;
      }
      var elapsed = Math.max(0, Math.floor((nowMs - startedMs) / 1000));
      var badge = line.querySelector(".run-elapsed");
      if (badge) {
        badge.textContent = elapsed > 0 ? String(elapsed) + "s" : "";
      }
    }

    var details = el.chatLog.querySelectorAll("details.run-details.run-thinking[data-started-at]");
    for (var j = 0; j < details.length; j += 1) {
      var panel = details[j];
      var started = panel.getAttribute("data-started-at") || "";
      var summary = panel.querySelector("summary");
      if (!summary) {
        continue;
      }
      var duration = thoughtDurationLabel(started, "");
      var summaryLabel = summary.querySelector(".run-summary-label");
      if (summaryLabel) {
        summaryLabel.textContent = "Working for " + (duration || "0s");
      } else {
        summary.textContent = "Working for " + (duration || "0s");
      }
    }
  }

  function syncRunThinkingPreviewScroll() {
    if (!el.chatLog) {
      return;
    }
    var panels = el.chatLog.querySelectorAll("details.run-details.run-thinking[data-event-id]");
    if (!panels || !panels.length) {
      return;
    }
    for (var i = 0; i < panels.length; i += 1) {
      var panel = panels[i];
      if (!panel.open) {
        continue;
      }
      var preview = panel.querySelector(".run-live-feed");
      if (preview) {
        var eventId = String(panel.getAttribute("data-event-id") || "");
        var autoFollow = true;
        if (
          eventId &&
          Object.prototype.hasOwnProperty.call(state.runStreamAutoFollowByEventId, eventId)
        ) {
          autoFollow = !!state.runStreamAutoFollowByEventId[eventId];
        }
        if (autoFollow) {
          preview.scrollTop = preview.scrollHeight;
          if (eventId) {
            state.runStreamScrollTopByEventId[eventId] = preview.scrollTop;
          }
          continue;
        }
        if (
          eventId &&
          Object.prototype.hasOwnProperty.call(state.runStreamScrollTopByEventId, eventId)
        ) {
          var savedTop = Number(state.runStreamScrollTopByEventId[eventId]);
          if (isFinite(savedTop) && savedTop >= 0) {
            var maxTop = Math.max(0, Number(preview.scrollHeight || 0) - Number(preview.clientHeight || 0));
            preview.scrollTop = Math.min(maxTop, savedTop);
          }
        }
      }
    }
  }

  function isElementScrollAtBottom(element, tolerancePx) {
    if (!element) {
      return true;
    }
    var tolerance = Number(tolerancePx || 0);
    if (!isFinite(tolerance) || tolerance < 0) {
      tolerance = 0;
    }
    var remaining = Number(element.scrollHeight || 0) - Number(element.scrollTop || 0) - Number(element.clientHeight || 0);
    return remaining <= tolerance;
  }

  function snapshotRunThinkingPreviewScroll() {
    if (!el.chatLog) {
      return;
    }
    var previews = el.chatLog.querySelectorAll("details.run-details.run-thinking[data-event-id] .run-live-feed");
    if (!previews || !previews.length) {
      return;
    }
    for (var i = 0; i < previews.length; i += 1) {
      var preview = previews[i];
      var panel = preview.closest("details.run-details.run-thinking[data-event-id]");
      if (!panel) {
        continue;
      }
      var eventId = String(panel.getAttribute("data-event-id") || "");
      if (!eventId) {
        continue;
      }
      state.runStreamScrollTopByEventId[eventId] = Number(preview.scrollTop || 0);
      state.runStreamAutoFollowByEventId[eventId] = isElementScrollAtBottom(preview, 8);
    }
  }

  function renderWorkspaceTree() {
    if (!state.workspaces.length) {
      var emptyMarkup = "";
      if (!state.initialLoadComplete) {
        emptyMarkup = "<p class='empty-state'><span class='run-spinner' aria-hidden='true'></span> Loading projects...</p>";
      } else {
        emptyMarkup = "<p class='empty-state'>Drop a folder here or click + to add a project.</p>";
      }
      if (state.workspaceTreeMarkupCache === emptyMarkup) {
        return;
      }
      el.workspaceTree.innerHTML = emptyMarkup;
      state.workspaceTreeMarkupCache = emptyMarkup;
      return;
    }

    var folderIcon =
      "<span class='workspace-icon' aria-hidden='true'>" +
        "<svg class='folder-closed' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'><path d='M1.8 4.2h4.1l1.4 1.7h6.9v7.2H1.8z'/></svg>" +
        "<svg class='folder-open' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'><path d='M1.5 5.7h4.2l1.3 1.4h6.5l-1.1 4.8H2.3z'/><path d='M1.7 5.7v-1.5h4.1l1.3 1.5'/></svg>" +
      "</span>";

    var html = "";
    var workspaces = getSortedWorkspaces();
    var showRelevantOnly = state.organizeShow === "relevant";
    var showRunningOnly = state.organizeShow === "running";

    if (state.organizeMode === "chrono") {
      var entries = [];
      for (var ci = 0; ci < workspaces.length; ci += 1) {
        var chronoWorkspace = workspaces[ci];
        var chronoWorkspaceId = chronoWorkspace.id;
        var chronoConversations = getSortedConversations(chronoWorkspace);
        for (var cj = 0; cj < chronoConversations.length; cj += 1) {
          var chronoConversation = chronoConversations[cj];
          if (showRunningOnly && !isConversationRunning(chronoWorkspaceId, chronoConversation)) {
            continue;
          }
          if (showRelevantOnly && !isConversationRelevant(chronoWorkspaceId, chronoConversation)) {
            continue;
          }
          entries.push({
            workspaceId: chronoWorkspaceId,
            workspaceName: chronoWorkspace.name || "Project",
            conversation: chronoConversation
          });
        }
      }

      entries.sort(function (a, b) {
        var as = state.sortMode === "created" ? conversationCreatedNumber(a.conversation) : conversationUpdatedNumber(a.conversation);
        var bs = state.sortMode === "created" ? conversationCreatedNumber(b.conversation) : conversationUpdatedNumber(b.conversation);
        if (as !== bs) {
          return bs - as;
        }
        return String(a.conversation.title || "").localeCompare(String(b.conversation.title || ""));
      });

      if (!entries.length) {
        html = "<p class='empty-state'>No threads match current organize filters.</p>";
      } else {
        for (var ei = 0; ei < entries.length; ei += 1) {
          var entry = entries[ei];
          var chronoActive = entry.conversation.id === state.activeConversationId ? " active" : "";
          var chronoPending = queueNumber(entry.conversation.queue_pending);
          var chronoRunning = String(entry.conversation.queue_running || "0") === "1";
          var chronoDone = String(entry.conversation.queue_done || "0") === "1";
          if (
            state.busy &&
            state.runningWorkspaceId === entry.workspaceId &&
            state.runningConversationId === entry.conversation.id
          ) {
            chronoRunning = true;
          }

          var chronoIndicatorClass = "thread-indicator";
          if (chronoRunning) {
            chronoIndicatorClass += " running";
          } else if (chronoDone && isConversationUnread(entry.workspaceId, entry.conversation)) {
            chronoIndicatorClass += " done";
          } else if (chronoPending > 0) {
            chronoIndicatorClass += " pending";
          }

          html += "<div class='conversation-row chrono-row" + chronoActive + "' role='button' tabindex='0' title='Open thread' data-action='select-conversation' data-workspace-id='" + escHtml(entry.workspaceId) + "' data-conversation-id='" + escHtml(entry.conversation.id) + "'>";
          html += "<span class='" + chronoIndicatorClass + "' aria-hidden='true'></span>";
          var chronoStatusMarkup = conversationStatusPillMarkup(entry.workspaceId, entry.conversation, chronoRunning);
          html += "<span class='conversation-title' title='" + escAttr(entry.workspaceName) + "'>" + escHtml(conversationDisplayTitle(entry.conversation.title)) + "</span>";
          html += chronoStatusMarkup;
          if (chronoPending > 0) {
            html += "<span class='queue-count'>" + chronoPending + "</span>";
          }
          html += conversationMetaMarkup(entry.workspaceId, entry.conversation);
          html += "</div>";
        }
      }
    } else {
      for (var i = 0; i < workspaces.length; i += 1) {
        var workspace = workspaces[i];
        var workspaceId = workspace.id;
        var isActiveWorkspace = workspaceId === state.activeWorkspaceId;
        var isExpanded = !!state.expandedWorkspaceIds[workspaceId];
        if (typeof state.expandedWorkspaceIds[workspaceId] === "undefined") {
          isExpanded = true;
          state.expandedWorkspaceIds[workspaceId] = true;
        }

        var filteredConversations = [];
        var conversations = getSortedConversations(workspace);
        for (var fc = 0; fc < conversations.length; fc += 1) {
          if (showRunningOnly && !isConversationRunning(workspaceId, conversations[fc])) {
            continue;
          }
          if (!showRelevantOnly || isConversationRelevant(workspaceId, conversations[fc])) {
            filteredConversations.push(conversations[fc]);
          }
        }

        if (showRunningOnly && !filteredConversations.length) {
          continue;
        }

        if (showRelevantOnly && !filteredConversations.length && !hasDraftForWorkspace(workspace) && !isActiveWorkspace) {
          continue;
        }

        var groupClass = "workspace-group";
        if (isExpanded) {
          groupClass += " expanded";
        }

        html += "<section class='" + groupClass + "' data-workspace-id='" + escHtml(workspaceId) + "'>";
        html += "<div class='workspace-row' data-action='select-workspace' data-workspace-id='" + escHtml(workspaceId) + "'>";
        html += folderIcon;
        html += "<button type='button' class='workspace-caret' data-action='toggle-workspace' data-workspace-id='" + escHtml(workspaceId) + "' aria-label='Toggle' title='Expand or collapse project'><span aria-hidden='true'>&rsaquo;</span></button>";
        var bgResidentsCount = Number(workspace.multi_agent_background_residents || 0);
        var workspaceLabel = escHtml(workspace.name || "Project");
        if (isFinite(bgResidentsCount) && bgResidentsCount > 0) {
          workspaceLabel += " <span class='workspace-brain-badge' title='Background agents active' aria-label='Background agents active'>🧠</span>";
        }
        html += "<div class='workspace-meta' title='" + escAttr(workspace.path || "") + "'>" + workspaceLabel + "</div>";
        html += "<button type='button' class='workspace-menu-trigger' data-action='toggle-workspace-menu' data-workspace-id='" + escHtml(workspaceId) + "' aria-label='Project menu' title='Project actions' aria-expanded='" + (state.openWorkspaceMenuWorkspaceId === workspaceId ? "true" : "false") + "'>&hellip;</button>";
        html += "<button type='button' class='workspace-new' data-action='new-conversation' data-workspace-id='" + escHtml(workspaceId) + "' aria-label='New thread' title='New thread'><span aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.35' stroke-linecap='round' stroke-linejoin='round'><rect x='2.2' y='2.1' width='11.6' height='11.8' rx='1.6'></rect><path d='M6.1 9.8l-.5 2 2-.5 3.8-3.8-1.5-1.5z'></path><path d='M9.8 6.1l1.5 1.5'></path></svg></span></button>";
        var workspaceMenuClass = "workspace-actions-pop floating-menu";
        if (state.openWorkspaceMenuWorkspaceId !== workspaceId) {
          workspaceMenuClass += " hidden";
        }
        html += "<div class='" + workspaceMenuClass + "' data-workspace-menu='" + escHtml(workspaceId) + "' role='menu' aria-label='Project actions'>";
        html += "<button type='button' data-action='open-workspace-multi_agent' data-workspace-id='" + escHtml(workspaceId) + "'>Manage agents</button>";
        html += "<button type='button' data-action='open-workspace-approvals' data-workspace-id='" + escHtml(workspaceId) + "'>Command approvals...</button>";
        html += "<button type='button' data-action='rename-workspace' data-workspace-id='" + escHtml(workspaceId) + "'>Rename</button>";
        html += "<button type='button' data-action='remove-workspace' data-workspace-id='" + escHtml(workspaceId) + "'>Remove</button>";
        html += "</div>";
        html += "</div>";

        html += "<div class='conversation-shell'>";

        if (hasDraftForWorkspace(workspace)) {
          var draftActive = state.activeDraftWorkspaceId === workspaceId ? " active" : "";
          html += "<button type='button' class='conversation-draft" + draftActive + "' data-action='select-draft' data-workspace-id='" + escHtml(workspaceId) + "'>Draft (unsent)</button>";
        }

        if (!filteredConversations.length && !hasDraftForWorkspace(workspace)) {
          html += "<div class='conversation-empty' aria-hidden='true'>No threads</div>";
        }

        for (var j = 0; j < filteredConversations.length; j += 1) {
          var conversation = filteredConversations[j];
          var activeConv = conversation.id === state.activeConversationId ? " active" : "";
          var queuePending = queueNumber(conversation.queue_pending);
          var queueRunning = String(conversation.queue_running || "0") === "1";
          var queueDone = String(conversation.queue_done || "0") === "1";
          if (
            state.busy &&
            state.runningWorkspaceId === workspaceId &&
            state.runningConversationId === conversation.id
          ) {
            queueRunning = true;
          }

          var indicatorClass = "thread-indicator";
          var unreadDone = queueDone && isConversationUnread(workspaceId, conversation);
          if (queueRunning) {
            indicatorClass += " running";
          } else if (unreadDone) {
            indicatorClass += " done";
          } else if (queuePending > 0) {
            indicatorClass += " pending";
          }

          html += "<div class='conversation-row" + activeConv + "' role='button' tabindex='0' title='Open thread' data-action='select-conversation' data-workspace-id='" + escHtml(workspaceId) + "' data-conversation-id='" + escHtml(conversation.id) + "'>";
          html += "<span class='" + indicatorClass + "' aria-hidden='true'></span>";
          var statusMarkup = conversationStatusPillMarkup(workspaceId, conversation, queueRunning);
          html += "<span class='conversation-title'>" + escHtml(conversationDisplayTitle(conversation.title)) + "</span>";
          html += statusMarkup;
          if (queuePending > 0) {
            html += "<span class='queue-count'>" + queuePending + "</span>";
          }
          html += conversationMetaMarkup(workspaceId, conversation);
          html += "</div>";
        }

        html += "</div>";
        html += "</section>";
      }
    }

    if (!trim(html)) {
      html = "<p class='empty-state'>No threads match current organize filters.</p>";
    }

    var triageCards = Array.isArray(state.triage && state.triage.cards) ? state.triage.cards : [];
    if (triageCards.length) {
      var triageHtml = "";
      triageHtml += "<section class='triage-inbox-section" + (state.activeTriage ? " active" : "") + "'>";
      triageHtml += "<div class='triage-inbox-head' data-action='select-triage'>";
      triageHtml += "<span class='triage-inbox-title'>Triage Inbox</span>";
      triageHtml += "<span class='triage-inbox-count'>" + escHtml(String(triageCards.length)) + "</span>";
      triageHtml += "</div>";
      triageHtml += "<div class='triage-inbox-actions'>";
      triageHtml += "<button type='button' class='ghost' data-action='triage-cleanup'>Cleanup...</button>";
      triageHtml += "<button type='button' class='ghost' data-action='triage-cleanup-directed'>Cleanup w/ prompt...</button>";
      triageHtml += "</div>";
      triageHtml += "<div class='triage-inbox-list'>";
      for (var tc = 0; tc < triageCards.length && tc < 14; tc += 1) {
        var card = triageCards[tc] || {};
        var cardId = String(card.id || "");
        if (!cardId) {
          continue;
        }
        var scopeLabel = multiAgentEscalationLabel(card.escalation_class || "");
        var targetLabel = multiAgentTargetTypeLabel(card.target_type || "");
        triageHtml += "<article class='triage-card'>";
        triageHtml += "<p class='triage-card-summary'>" + escHtml(card.summary || "Proposal") + "</p>";
        triageHtml += "<p class='triage-card-meta'>" + escHtml(scopeLabel || "Policy tradeoff");
        if (targetLabel) {
          triageHtml += " • " + escHtml(targetLabel);
        }
        triageHtml += "</p>";
        var suppressMenuOpen = String(state.openTriageSuppressProposalId || "") === cardId;
        triageHtml += "<div class='triage-card-actions'>";
        triageHtml += "<button type='button' data-action='triage-open-context' data-workspace-id='" + escAttr(card.workspace_id || "") + "' data-conversation-id='" + escAttr(card.conversation_id || "") + "' data-proposal-id='" + escAttr(cardId) + "'>Open</button>";
        triageHtml += "<button type='button' data-action='triage-decide' data-proposal-id='" + escAttr(cardId) + "'>Decide</button>";
        triageHtml += "<span class='menu-anchor triage-scope-anchor'>";
        triageHtml += "<button type='button' data-action='triage-suppress-open' data-proposal-id='" + escAttr(cardId) + "' aria-expanded='" + (suppressMenuOpen ? "true" : "false") + "'>Create filter...</button>";
        triageHtml += "<div class='floating-menu triage-scope-menu" + (suppressMenuOpen ? "" : " hidden") + "' data-triage-scope-menu='" + escAttr(cardId) + "'>";
        triageHtml += "<button type='button' data-action='triage-suppress-scope' data-proposal-id='" + escAttr(cardId) + "' data-scope='workspace'>This project</button>";
        triageHtml += "<button type='button' data-action='triage-suppress-scope' data-proposal-id='" + escAttr(cardId) + "' data-scope='global'>All projects</button>";
        triageHtml += "</div>";
        triageHtml += "</span>";
        triageHtml += "</div>";
        triageHtml += "</article>";
      }
      if (triageCards.length > 14) {
        triageHtml += "<p class='settings-hint'>+" + escHtml(String(triageCards.length - 14)) + " more proposals in Triage.</p>";
      }
      triageHtml += "</div>";
      triageHtml += "</section>";
      html = triageHtml + "<div class='workspace-tree-section-head'>Threads</div>" + html;
    }

    if (state.workspaceTreeMarkupCache === html) {
      return;
    }

    el.workspaceTree.innerHTML = html;
    state.workspaceTreeMarkupCache = html;
  }

  function renderModelStatus() {
    if (!el.modelStatusBtn) {
      return;
    }
    if (state.modelLoadError) {
      el.modelStatusBtn.textContent = "Models unavailable";
      el.modelStatusBtn.title = "Could not read Ollama models";
      return;
    }
    var installedCount = Number(state.models.length || 0);
    var downloadingCount = 0;
    var installingCount = 0;
    var runningOtherCount = 0;
    var runningSeen = {};

    for (var i = 0; i < state.modelInstalls.length; i += 1) {
      var job = state.modelInstalls[i] || {};
      if (String(job.status || "") !== "running") {
        continue;
      }
      var jobId = String(job.id || "");
      if (jobId && runningSeen[jobId]) {
        continue;
      }
      if (jobId) {
        runningSeen[jobId] = true;
      }
      var phase = String(job.phase || "").toLowerCase();
      if (phase === "downloading") {
        downloadingCount += 1;
      } else if (phase === "installing") {
        installingCount += 1;
      } else {
        runningOtherCount += 1;
      }
    }

    var hasExtraRunning = false;
    if (state.modelInstallJob && String(state.modelInstallJob.status || "") === "running") {
      var activeJobId = String(state.modelInstallJob.id || "");
      if (!activeJobId || !runningSeen[activeJobId]) {
        hasExtraRunning = true;
        var activePhase = String(state.modelInstallJob.phase || "").toLowerCase();
        if (activePhase === "downloading") {
          downloadingCount += 1;
        } else if (activePhase === "installing") {
          installingCount += 1;
        } else {
          runningOtherCount += 1;
        }
      }
    }

    if (!installedCount && !downloadingCount && !installingCount && !runningOtherCount) {
      el.modelStatusBtn.textContent = "No models";
      el.modelStatusBtn.title = "No Ollama models detected";
      return;
    }

    var noun = installedCount === 1 ? "model" : "models";
    var parts = [installedCount + " " + noun];
    if (downloadingCount > 0) {
      parts.push(downloadingCount + " downloading");
    }
    if (installingCount > 0) {
      parts.push(installingCount + " installing");
    }
    if (runningOtherCount > 0) {
      parts.push(runningOtherCount + " preparing");
    }
    el.modelStatusBtn.textContent = parts.join(", ");

    var title = installedCount + " Ollama " + noun + " installed";
    if (downloadingCount > 0 || installingCount > 0 || runningOtherCount > 0 || hasExtraRunning) {
      var tail = [];
      if (downloadingCount > 0) {
        tail.push(downloadingCount + " downloading");
      }
      if (installingCount > 0) {
        tail.push(installingCount + " installing");
      }
      if (runningOtherCount > 0) {
        tail.push(runningOtherCount + " preparing");
      }
      if (tail.length) {
        title += ", " + tail.join(", ");
      }
    }
    el.modelStatusBtn.title = title;
  }

  function isModelInstalled(modelName) {
    var target = String(modelName || "");
    if (!target) {
      return false;
    }
    for (var i = 0; i < state.models.length; i += 1) {
      if (String(state.models[i]) === target) {
        return true;
      }
    }
    return false;
  }

  function currentModelInstallFor(modelName) {
    var target = String(modelName || "");
    if (!target || !Array.isArray(state.modelInstalls)) {
      return null;
    }
    for (var i = 0; i < state.modelInstalls.length; i += 1) {
      var job = state.modelInstalls[i] || {};
      if (String(job.model || "") !== target) {
        continue;
      }
      if (String(job.status || "") === "running") {
        return job;
      }
      if (!state.modelInstallJob || String(job.id || "") === String(state.modelInstallJob.id || "")) {
        return job;
      }
    }
    return null;
  }

  function formatCatalogSizeLabel(sizeRaw) {
    var parsed = Number(sizeRaw);
    if (!isFinite(parsed) || parsed <= 0) {
      return "";
    }
    return parsed.toFixed(1) + "GB";
  }

  function numericProgressPercent(rawValue) {
    var parsed = Number(rawValue);
    if (!isFinite(parsed)) {
      return -1;
    }
    var rounded = Math.round(parsed);
    if (rounded < 0) {
      rounded = 0;
    }
    if (rounded > 100) {
      rounded = 100;
    }
    return rounded;
  }

  function modelInstallStatusLabel(job) {
    var installJob = job || {};
    var status = String(installJob.status || "");
    var phase = String(installJob.phase || "");
    var pct = numericProgressPercent(installJob.progress_pct);
    if (status === "done") {
      return "Installed";
    }
    if (status === "failed") {
      return "Retry install";
    }
    if (phase === "downloading") {
      if (pct >= 0) {
        return "Downloading " + String(pct) + "%";
      }
      return "Downloading…";
    }
    if (phase === "installing") {
      return "Installing…";
    }
    return "Installing…";
  }

  function renderModelsDialog() {
    if (!el.modelsBoxList) {
      return;
    }

    var activeModel = activeModelName();
    var html = "";
    if (state.modelLoadError) {
      html += "<p class='empty-state'>Could not load models right now.</p>";
    }

    html += "<div class='models-section'><p class='models-section-title'>Installed</p>";
    if (!state.models.length) {
      html += "<p class='empty-state'>No installed models yet.</p>";
    } else {
      for (var i = 0; i < state.models.length; i += 1) {
        var model = state.models[i];
        var parts = parseModelDisplay(model);
        var activeClass = model === activeModel ? " active" : "";
        html += "<button type='button' class='model-item" + activeClass + "' data-model-name='" + escHtml(model) + "'>";
        html += "<span class='model-primary'>" + escHtml(parts.primary) + "</span>";
        html += "<span class='model-meta'>" + escHtml(parts.meta || parts.raw) + "</span>";
        html += "</button>";
      }
    }
    html += "</div>";

    html += "<div class='models-section'><p class='models-section-title'>Install curated models</p>";
    if (!Array.isArray(state.modelCatalog) || !state.modelCatalog.length) {
      html += "<p class='empty-state'>No curated models list found.</p>";
    } else {
      for (var j = 0; j < state.modelCatalog.length; j += 1) {
        var entry = state.modelCatalog[j] || {};
        var modelName = String(entry.name || "");
        if (!modelName) {
          continue;
        }
        var modelParts = parseModelDisplay(modelName);
        var description = trim(entry.description || "");
        var sizeLabel = formatCatalogSizeLabel(entry.size_gb);
        var isInstalled = isModelInstalled(modelName);
        var installJob = currentModelInstallFor(modelName);
        var isInstalling = !!(installJob && String(installJob.status || "") === "running");
        var isFailedInstall = !!(installJob && String(installJob.status || "") === "failed");
        var installLabel = isInstalled ? "Installed" : (installJob ? modelInstallStatusLabel(installJob) : "Install");
        var installDisabled = isInstalled || isInstalling;
        if (isFailedInstall && !isInstalled) {
          installDisabled = false;
        }
        html += "<div class='catalog-item'>";
        html += "<div class='catalog-copy'><span class='model-primary'>" + escHtml(modelParts.primary) + "</span>";
        html += "<span class='model-meta'>" + escHtml(modelParts.meta || modelParts.raw) + "</span>";
        if (sizeLabel) {
          html += "<span class='catalog-size'>" + escHtml(sizeLabel) + "</span>";
        }
        if (description) {
          html += "<span class='catalog-description'>" + escHtml(description) + "</span>";
        }
        html += "</div>";
        html += "<button type='button' class='catalog-install-btn" + (installDisabled ? " disabled" : "") + "' data-action='install-model' data-model-name='" + escHtml(modelName) + "'" + (installDisabled ? " disabled" : "") + ">" + escHtml(installLabel) + "</button>";
        html += "</div>";
      }
    }
    html += "</div>";

    if (state.modelInstallJob && trim(state.modelInstallLog || "")) {
      var jobModel = String(state.modelInstallJob.model || "");
      var jobStatus = String(state.modelInstallJob.status || "running");
      var jobPhase = String(state.modelInstallJob.phase || "");
      var jobProgress = numericProgressPercent(state.modelInstallJob.progress_pct);
      var phaseLabel = "";
      if (jobStatus === "running") {
        if (jobPhase === "downloading") {
          phaseLabel = jobProgress >= 0
            ? "downloading " + String(jobProgress) + "%"
            : "downloading";
        } else if (jobPhase === "installing") {
          phaseLabel = "installing";
        }
      }
      html += "<div class='models-section install-log-section'>";
      html += "<p class='models-section-title'>Install log: " + escHtml(jobModel) + " (" + escHtml(jobStatus + (phaseLabel ? ", " + phaseLabel : "")) + ")</p>";
      html += "<pre class='install-log'>" + escHtml(state.modelInstallLog) + "</pre>";
      html += "</div>";
    }

    el.modelsBoxList.innerHTML = html;
  }

  function themeLabel(name) {
    var raw = String(name || "");
    if (!raw) {
      return "Psionic";
    }
    return raw
      .replace(/[-_]+/g, " ")
      .replace(/\b[a-z]/g, function (m) {
        return m.toUpperCase();
      });
  }

  function themeNameListFallback() {
    return [
      "psionic",
      "adept",
      "alchemist",
      "archmage",
      "chronomancer",
      "conjurer",
      "druid",
      "empath",
      "enchanter",
      "geomancer",
      "hermeticist",
      "hierophant",
      "illusionist",
      "lich",
      "necromancer",
      "pyromancer",
      "seer",
      "shaman",
      "sorcerer",
      "sorceress",
      "technomancer",
      "thaumaturge",
      "thelemite",
      "theurgist",
      "wadjet",
      "warlock",
      "wizard"
    ];
  }

  function normalizeThemes(list) {
    var out = [];
    var seen = {};
    var input = Array.isArray(list) ? list : [];
    for (var i = 0; i < input.length; i += 1) {
      var item = trim(String(input[i] || "")).toLowerCase();
      if (!item || !/^[a-z0-9_-]+$/.test(item) || seen[item]) {
        continue;
      }
      seen[item] = true;
      out.push(item);
    }
    if (!seen.psionic) {
      out.unshift("psionic");
    }
    out.sort(function (a, b) {
      return a.localeCompare(b);
    });
    return out;
  }

  function ensureActiveThemeInList() {
    if (!state.themes.length) {
      state.themes = normalizeThemes(themeNameListFallback());
    }
    if (state.themes.indexOf(state.activeTheme) < 0) {
      state.activeTheme = "psionic";
      storageSet("artificer.activeTheme", state.activeTheme);
    }
  }

  function applyTheme(themeName) {
    var normalized = trim(String(themeName || "")).toLowerCase();
    if (!normalized || !/^[a-z0-9_-]+$/.test(normalized)) {
      normalized = "psionic";
    }
    state.activeTheme = normalized;
    storageSet("artificer.activeTheme", normalized);
    if (document && document.documentElement) {
      document.documentElement.setAttribute("data-theme", normalized);
    }
    if (el.themeStylesheet) {
      el.themeStylesheet.href = "/static/themes/" + normalized + ".css?v=20260217-themefix01";
    }
  }

  function renderThemePicker() {
    if (!el.themePickerBtn || !el.themePickerList) {
      return;
    }
    ensureActiveThemeInList();
    el.themePickerBtn.textContent = themeLabel(state.activeTheme);
    el.themePickerBtn.setAttribute("data-tooltip", "Theme: " + themeLabel(state.activeTheme));

    var html = "";
    for (var i = 0; i < state.themes.length; i += 1) {
      var theme = state.themes[i];
      var activeClass = theme === state.activeTheme ? " active" : "";
      html += "<button type='button' class='theme-item" + activeClass + "' data-theme-name='" + escAttr(theme) + "'>" + escHtml(themeLabel(theme)) + "</button>";
    }
    el.themePickerList.innerHTML = html;
  }

  function cycleTheme(step) {
    ensureActiveThemeInList();
    if (!state.themes.length) {
      return;
    }
    var delta = step < 0 ? -1 : 1;
    var currentIndex = state.themes.indexOf(state.activeTheme);
    if (currentIndex < 0) {
      currentIndex = 0;
    }
    var nextIndex = currentIndex + delta;
    if (nextIndex < 0) {
      nextIndex = state.themes.length - 1;
    } else if (nextIndex >= state.themes.length) {
      nextIndex = 0;
    }
    applyTheme(state.themes[nextIndex]);
    renderThemePicker();
  }

  function renderModelListInto(containerEl, activeModel) {
    if (!containerEl) {
      return;
    }

    if (!state.models.length) {
      containerEl.innerHTML = "<p class='empty-state'>No models detected.</p>";
      return;
    }

    var html = "";
    for (var i = 0; i < state.models.length; i += 1) {
      var model = state.models[i];
      var parts = parseModelDisplay(model);
      var activeClass = model === activeModel ? " active" : "";
      html += "<button type='button' class='model-item" + activeClass + "' data-model-name='" + escHtml(model) + "'>";
      html += "<span class='model-primary'>" + escHtml(parts.primary) + "</span>";
      html += "<span class='model-meta'>" + escHtml(parts.meta || parts.raw) + "</span>";
      html += "</button>";
    }

    containerEl.innerHTML = html;
  }

  function renderModelPickerButton() {
    if (!el.modelPickerBtn) {
      return;
    }
    var model = activeModelName();
    if (!model) {
      el.modelPickerBtn.innerHTML = "<span class='model-primary'>Select model</span>";
      return;
    }
    var parts = parseModelDisplay(model);
    el.modelPickerBtn.innerHTML = "<span class='model-primary'>" + escHtml(parts.primary) + "</span><span class='model-meta'>" + escHtml(parts.meta || parts.raw) + "</span>";
  }

  function renderRunModeMoreList() {
    if (!el.runModeMoreList) {
      return;
    }
    var runtime = normalizeModeRuntime(state.modeRuntime);
    var modes = Array.isArray(runtime.modes) ? runtime.modes.slice(0) : [];
    var html = "";
    html += "<button type='button' class='run-mode-advanced-item' data-assistant-mode-id=''>";
    html += "<span class='run-mode-row'><span class='run-mode-name'>Assistant (General)</span><span class='check' aria-hidden='true'>&check;</span></span>";
    html += "<span class='run-mode-blurb'>General assistant behavior.</span>";
    html += "</button>";
    for (var i = 0; i < modes.length; i += 1) {
      var mode = modes[i] || {};
      var modeId = trim(String(mode.id || ""));
      if (!modeId) {
        continue;
      }
      var blurb = trim(String(mode.description || ""));
      var details = blurb || "Specialized governance mode.";
      html += "<button type='button' class='run-mode-advanced-item' data-assistant-mode-id='" + escAttr(modeId) + "'>";
      html += "<span class='run-mode-row'><span class='run-mode-name'>" + escHtml(mode.name || modeId) + "</span><span class='check' aria-hidden='true'>&check;</span></span>";
      html += "<span class='run-mode-blurb'>" + escHtml(details) + "</span>";
      html += "</button>";
    }
    if (!modes.length) {
      html += "<p class='settings-hint' style='margin:0;padding:8px 10px;'>Mode Runtime unavailable. Open Settings to initialize modes.</p>";
    }
    el.runModeMoreList.innerHTML = html;
  }

  function renderRunControls() {
    if (el.runModeBtn) {
      var mode = normalizeRunMode(state.runMode);
      el.runModeBtn.textContent = runModeLabel(mode);
      el.runModeBtn.title = runModeDescription(mode);
      el.runModeBtn.setAttribute("aria-label", "Run mode: " + runModeLabel(mode) + ". " + runModeDescription(mode));
    }

    if (el.runModeMenu) {
      renderRunModeMoreList();
      var modeItems = el.runModeMenu.querySelectorAll("button[data-run-mode]");
      for (var mi = 0; mi < modeItems.length; mi += 1) {
        var modeValue = normalizeRunMode(modeItems[mi].getAttribute("data-run-mode"));
        modeItems[mi].classList.toggle("active", modeValue === normalizeRunMode(state.runMode));
        var modeBlurb = modeItems[mi].querySelector(".run-mode-blurb");
        if (modeBlurb) {
          modeBlurb.classList.toggle("hidden", !state.runModeMoreExpanded);
        }
      }
      var advancedItems = el.runModeMenu.querySelectorAll("button[data-assistant-mode-id]");
      for (var ai = 0; ai < advancedItems.length; ai += 1) {
        var profileId = trim(String(advancedItems[ai].getAttribute("data-assistant-mode-id") || ""));
        var active = normalizeRunMode(state.runMode) === "assistant" && profileId === normalizeAssistantModeId(state.assistantModeId);
        advancedItems[ai].classList.toggle("active", active);
      }
    }

    if (el.runModeMoreToggle) {
      el.runModeMoreToggle.setAttribute("aria-expanded", state.runModeMoreExpanded ? "true" : "false");
    }
    if (el.runModeMoreList) {
      el.runModeMoreList.classList.toggle("hidden", !state.runModeMoreExpanded);
    }

    if (el.agentLoopToggle) {
      el.agentLoopToggle.classList.toggle("on", !!state.agentLoopEnabled);
      el.agentLoopToggle.setAttribute("aria-pressed", state.agentLoopEnabled ? "true" : "false");
      el.agentLoopToggle.title = state.agentLoopEnabled ? "Advanced agentive loop is on" : "Quick single-pass mode is on";
    }

    if (el.reasoningMenuBtn) {
      el.reasoningMenuBtn.innerHTML =
        "<span class='menu-icon reasoning-brain-icon' aria-hidden='true'>" + reasoningIconMarkup() + "</span>" +
        "<span>" + escHtml(reasoningLabel(state.reasoningEffort)) + "</span>";
    }

    if (el.reasoningMenu) {
      var buttons = el.reasoningMenu.querySelectorAll("button[data-reasoning]");
      for (var i = 0; i < buttons.length; i += 1) {
        var level = buttons[i].getAttribute("data-reasoning");
        buttons[i].classList.toggle("active", level === state.reasoningEffort);
      }
    }

    if (el.computeMenuBtn) {
      el.computeMenuBtn.innerHTML =
        "<span class='menu-icon compute-clock-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.35' stroke-linecap='round' stroke-linejoin='round'><circle cx='8' cy='8' r='5.6'></circle><path d='M8 4.9v3.4l2.2 1.4'></path></svg></span>" +
        "<span>" + escHtml(computeBudgetLabel(state.computeBudget)) + "</span>";
      el.computeMenuBtn.setAttribute("aria-label", "Compute budget: " + computeBudgetLabel(state.computeBudget));
    }

    if (el.computeMenu) {
      var computeButtons = el.computeMenu.querySelectorAll("button[data-compute-budget]");
      for (var ci = 0; ci < computeButtons.length; ci += 1) {
        var budget = normalizeComputeBudget(computeButtons[ci].getAttribute("data-compute-budget"));
        computeButtons[ci].classList.toggle("active", budget === normalizeComputeBudget(state.computeBudget));
      }
    }
  }

  function renderRunButton() {
    if (!el.runBtn) {
      return;
    }
    var hasPrompt = trim(el.runPrompt ? el.runPrompt.value : "") !== "";
    var canRun = hasPrompt && !!(state.activeWorkspaceId || state.activeDraftWorkspaceId || state.activeConversationId);
    var runningHere =
      state.busy &&
      state.activeWorkspaceId &&
      state.activeConversationId &&
      state.runningWorkspaceId === state.activeWorkspaceId &&
      state.runningConversationId === state.activeConversationId;

    el.runBtn.disabled = !canRun;
    if (runningHere) {
      el.runBtn.classList.add("running");
      el.runBtn.innerHTML = "<span aria-hidden='true'>...</span>";
    } else {
      el.runBtn.classList.remove("running");
      el.runBtn.innerHTML = "<span aria-hidden='true'>&uarr;</span>";
    }
  }

  function renderQueueControls() {
    if (!el.queueControls) {
      return;
    }
    if (!state.activeWorkspaceId || !state.activeConversationId || !el.queueSteerBtn || !el.queueCancelBtn) {
      el.queueControls.classList.add("hidden");
      return;
    }

    var stats = activeConversationQueueStats();
    if (stats.pending < 1 || !stats.firstId) {
      el.queueControls.classList.add("hidden");
      return;
    }

    var queueItemId = stats.firstId;
    var preferredId = state.lastQueuedItemIdByConversation[state.activeConversationId] || "";
    if (preferredId) {
      queueItemId = preferredId;
    }

    el.queueSteerBtn.textContent = "Steer";
    if (stats.pending > 1) {
      el.queueSteerBtn.textContent = "Steer (" + stats.pending + ")";
    }
    el.queueSteerBtn.dataset.queueItemId = queueItemId;
    el.queueCancelBtn.dataset.queueItemId = queueItemId;
    el.queueSteerBtn.disabled = !queueItemId;
    el.queueCancelBtn.disabled = !queueItemId;
    el.queueControls.classList.remove("hidden");
  }

  function queueItemMetaLabel(item, index) {
    var parts = [];
    parts.push("Queued #" + String(index + 1));
    if (item && item.run_mode) {
      parts.push(runModeLabel(item.run_mode));
    }
    if (item && item.compute_budget) {
      parts.push(computeBudgetLabel(item.compute_budget));
    }
    if (item && Array.isArray(item.explicit_skill_ids) && item.explicit_skill_ids.length) {
      parts.push(String(item.explicit_skill_ids.length) + " skill" + (item.explicit_skill_ids.length === 1 ? "" : "s"));
    }
    return parts.join(" • ");
  }

  function runChecklistTaskKey(rawText) {
    var text = trim(String(rawText || "")).toLowerCase();
    if (!text) {
      return "";
    }
    text = text.replace(/[^a-z0-9 ]+/g, " ");
    text = text.replace(/\s+/g, " ");
    return trim(text);
  }

  function runChecklistTokens(rawText) {
    var words = runChecklistTaskKey(rawText).split(/\s+/);
    var tokens = [];
    var stop = {
      a: 1, an: 1, and: 1, are: 1, as: 1, at: 1, be: 1, by: 1, for: 1, from: 1, in: 1, into: 1, is: 1, it: 1, of: 1, on: 1, or: 1, that: 1, the: 1, to: 1, with: 1
    };
    for (var i = 0; i < words.length; i += 1) {
      var token = trim(words[i] || "");
      if (token.length < 3 || stop[token]) {
        continue;
      }
      tokens.push(token);
    }
    return tokens;
  }

  function runChecklistTasksFromText(rawText) {
    var text = normalizeRunNarrativeText(rawText);
    if (!text) {
      return [];
    }
    text = text.replace(/\r\n?/g, "\n");
    text = text.replace(/\s*(Goal:|Subgoals:|Constraints:|Unknowns:|Next Action:|Completion Criteria:|Plan:|PLAN_UPDATE:)\s*/g, "\n$1\n");
    text = text.replace(/\s*(\d+[\.\)])\s+/g, "\n$1 ");
    text = text.replace(/\s*([\-*•])\s+/g, "\n$1 ");
    text = text.replace(/\n{3,}/g, "\n\n");

    var lines = text.split(/\n+/);
    var tasks = [];
    var seen = {};
    var capturingSubgoals = false;
    var sawSubgoalsHeader = false;

    function pushTask(lineText) {
      var line = trim(String(lineText || ""));
      if (!line) {
        return;
      }
      var done = false;
      if (/^(?:\[[xX]\]|[\-*•]\s+\[[xX]\]|\d+[\.\)]\s+\[[xX]\])\s+/.test(line)) {
        done = true;
      }
      line = line.replace(/^[\-*•]\s+\[[ xX]\]\s+/, "");
      line = line.replace(/^\[[ xX]\]\s+/, "");
      line = line.replace(/^\d+[\.\)]\s+\[[ xX]\]\s+/, "");
      line = line.replace(/^[\-*•]\s+/, "");
      line = line.replace(/^\d+[\.\)]\s+/, "");
      line = trim(line);
      if (!line) {
        return;
      }
      var key = runChecklistTaskKey(line);
      if (!key || seen[key]) {
        return;
      }
      seen[key] = 1;
      tasks.push({
        text: line,
        done: done
      });
    }

    for (var i = 0; i < lines.length; i += 1) {
      var line = trim(lines[i] || "");
      if (!line) {
        continue;
      }
      if (/^Subgoals:/i.test(line)) {
        capturingSubgoals = true;
        sawSubgoalsHeader = true;
        continue;
      }
      if (
        capturingSubgoals &&
        /^(Constraints|Unknowns|Next Action|Completion Criteria|Goal|Plan|PLAN_UPDATE|Current mode|Mode State|Transition|Checkpoint):/i.test(line)
      ) {
        capturingSubgoals = false;
      }
      var isTaskLine = /^(\[[ xX]\]|\d+[\.\)]|[\-*•])\s+/.test(line);
      if (capturingSubgoals) {
        if (isTaskLine) {
          pushTask(line);
        } else if (tasks.length && !/^[A-Za-z][A-Za-z0-9 _-]{1,40}:$/.test(line)) {
          tasks[tasks.length - 1].text = trim(tasks[tasks.length - 1].text + " " + line);
        }
        continue;
      }
      if (!sawSubgoalsHeader && isTaskLine) {
        pushTask(line);
      }
    }

    if (tasks.length > 18) {
      tasks = tasks.slice(0, 18);
    }
    return tasks;
  }

  function runChecklistCompletionEvidence(event) {
    var evidence = [];
    var entries = splitRunStreamEntries(event && event.stream_text);
    for (var i = 0; i < entries.length; i += 1) {
      var text = trim(String((entries[i] && entries[i].text) || ""));
      if (!text) {
        continue;
      }
      var lower = text.toLowerCase();
      if (!/(done|completed|finished|implemented|verified|passed|resolved|validated)/.test(lower)) {
        continue;
      }
      if (/(not done|not completed|not finished|failed|failure|error|blocked|mismatch)/.test(lower)) {
        continue;
      }
      evidence.push({
        text: text,
        lower: lower
      });
    }
    if (evidence.length > 120) {
      evidence = evidence.slice(evidence.length - 120);
    }
    return evidence;
  }

  function runChecklistMarkCompletions(tasks, event) {
    var list = Array.isArray(tasks) ? tasks.slice() : [];
    if (!list.length) {
      return [];
    }

    var evidence = runChecklistCompletionEvidence(event);
    if (!evidence.length) {
      return list;
    }

    var taskTokens = [];
    for (var i = 0; i < list.length; i += 1) {
      taskTokens.push(runChecklistTokens(list[i] && list[i].text));
    }

    for (var j = 0; j < evidence.length; j += 1) {
      var line = evidence[j] || {};
      var indexMatch = String(line.lower || "").match(/\b(?:task|step)\s*#?\s*(\d{1,2})\b/);
      if (indexMatch) {
        var explicitIndex = Number(indexMatch[1] || 0) - 1;
        if (explicitIndex >= 0 && explicitIndex < list.length) {
          list[explicitIndex].done = true;
        }
      }
    }

    for (var k = 0; k < list.length; k += 1) {
      if (list[k].done) {
        continue;
      }
      var tokens = taskTokens[k] || [];
      if (!tokens.length) {
        continue;
      }
      for (var n = 0; n < evidence.length; n += 1) {
        var ev = evidence[n] || {};
        var evTokens = runChecklistTokens(ev.text || "");
        if (!evTokens.length) {
          continue;
        }
        var overlap = 0;
        for (var t = 0; t < tokens.length; t += 1) {
          for (var u = 0; u < evTokens.length; u += 1) {
            if (tokens[t] === evTokens[u]) {
              overlap += 1;
              break;
            }
          }
        }
        var required = tokens.length >= 5 ? 3 : 2;
        if (overlap >= required) {
          list[k].done = true;
          break;
        }
      }
    }

    return list;
  }

  function buildRunChecklistForEvent(event) {
    var structured = normalizeRunTaskStatusSnapshot(event && event.task_status);
    if (!structured || structured.total < 1) {
      return {
        tasks: [],
        completed: 0,
        total: 0,
        source: "backend"
      };
    }
    return {
      tasks: structured.tasks,
      completed: structured.completed,
      total: structured.total,
      source: structured.source || "backend"
    };
  }

  function findLatestRunChecklist(conversationId) {
    var convId = String(conversationId || "");
    if (!convId) {
      return null;
    }
    var activeEvent = findLatestRunEventByStatus(convId, ["running"]);
    if (activeEvent) {
      var activeChecklist = buildRunChecklistForEvent(activeEvent);
      if (activeChecklist.total > 0) {
        activeChecklist.event = activeEvent;
        return activeChecklist;
      }
      return null;
    }
    var events = runEventsForConversation(convId);
    if (!events.length) {
      return null;
    }
    var minIndex = events.length - 6;
    if (minIndex < 0) {
      minIndex = 0;
    }
    for (var i = events.length - 1; i >= minIndex; i -= 1) {
      var event = events[i] || {};
      var checklist = buildRunChecklistForEvent(event);
      if (checklist.total > 0) {
        checklist.event = event;
        return checklist;
      }
    }
    return null;
  }

  function renderRunTodoMonitor() {
    if (!el.runTodoMonitor || !el.runTodoMonitorLabel || !el.runTodoMonitorList) {
      return;
    }
    if (!state.activeWorkspaceId || !state.activeConversationId || state.activeDraftWorkspaceId) {
      el.runTodoMonitor.classList.add("hidden");
      return;
    }

    var checklist = findLatestRunChecklist(state.activeConversationId);
    if (!checklist || checklist.total < 1) {
      el.runTodoMonitor.classList.add("hidden");
      return;
    }

    var conversationKey = queueConversationKey(state.activeWorkspaceId, state.activeConversationId);
    var hasPreference = Object.prototype.hasOwnProperty.call(state.runTodoMonitorOpenByConversation, conversationKey);
    var shouldOpen = hasPreference ? !!state.runTodoMonitorOpenByConversation[conversationKey] : true;
    el.runTodoMonitor.open = shouldOpen;
    var checklistIsRunning = !!(checklist.event && String(checklist.event.status || "") === "running");
    el.runTodoMonitorLabel.classList.toggle("meta-glimmer", checklistIsRunning);
    el.runTodoMonitorLabel.textContent =
      String(checklist.completed) + " out of " + String(checklist.total) + " task" + (checklist.total === 1 ? "" : "s") + " completed";

    var html = "";
    for (var i = 0; i < checklist.tasks.length; i += 1) {
      var task = checklist.tasks[i] || {};
      html += "<li class='run-todo-item" + (task.done ? " done" : "") + "'>";
      html += "<span class='run-todo-check' aria-hidden='true'></span>";
      html += "<span class='run-todo-text'>" + escHtml(task.text || "") + "</span>";
      html += "</li>";
    }
    el.runTodoMonitorList.innerHTML = html;
    el.runTodoMonitor.classList.remove("hidden");
  }

  function runEventTerminalPreview(event) {
    var lines = [];
    var entries = splitRunStreamEntries(event && event.stream_text);
    var commandRegex = /(^|\b)(COMMANDS?:|COMMAND:|\/bin\/|apply_patch|git |rg |ls |cat |sed |awk |npm |pnpm |yarn |python |node |go |cargo |make |godot |sh |bash |zsh )/i;
    for (var i = 0; i < entries.length; i += 1) {
      var entry = entries[i] || {};
      var text = trim(String(entry.text || ""));
      if (!text) {
        continue;
      }
      if (commandRegex.test(text)) {
        lines.push((entry.time ? "[" + entry.time + "] " : "") + text);
      }
    }
    if (!lines.length) {
      for (var j = Math.max(0, entries.length - 20); j < entries.length; j += 1) {
        var fallback = entries[j] || {};
        var fallbackText = trim(String(fallback.text || ""));
        if (!fallbackText) {
          continue;
        }
        lines.push((fallback.time ? "[" + fallback.time + "] " : "") + fallbackText);
      }
    }
    if (!lines.length && event && Array.isArray(event.commands) && event.commands.length) {
      for (var c = 0; c < event.commands.length; c += 1) {
        var cmd = trim(String((event.commands[c] && event.commands[c].command) || ""));
        if (!cmd) {
          continue;
        }
        lines.push("$ " + cmd);
      }
    }
    if (!lines.length) {
      return "";
    }
    if (lines.length > 40) {
      lines = lines.slice(lines.length - 40);
    }
    return lines.join("\n");
  }

  function renderRunTerminalMonitor() {
    if (!el.runTerminalMonitor || !el.runTerminalMonitorLabel || !el.runTerminalMonitorOutput) {
      return;
    }
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      el.runTerminalMonitor.classList.add("hidden");
      return;
    }
    var stats = activeConversationQueueStats();
    var event = findLatestRunEventByStatus(state.activeConversationId, ["running"]);
    var activeRunMatch = !!(
      state.busy &&
      String(state.runningWorkspaceId || "") === String(state.activeWorkspaceId || "") &&
      String(state.runningConversationId || "") === String(state.activeConversationId || "")
    );
    if (!event && !stats.running && !activeRunMatch) {
      el.runTerminalMonitor.classList.add("hidden");
      return;
    }

    var conversationKey = queueConversationKey(state.activeWorkspaceId, state.activeConversationId);
    var shouldOpen = !!state.runTerminalMonitorOpenByConversation[conversationKey];
    el.runTerminalMonitor.open = shouldOpen;
    el.runTerminalMonitor.classList.remove("hidden");
    var terminalIsRunning = !!(event || stats.running || activeRunMatch);
    el.runTerminalMonitorLabel.classList.toggle("meta-glimmer", terminalIsRunning);
    el.runTerminalMonitorLabel.textContent = "Running 1 terminal";
    el.runTerminalMonitorOutput.textContent = runEventTerminalPreview(event) || "Waiting for terminal activity...";
    if (el.runTerminalMonitorStop) {
      el.runTerminalMonitorStop.dataset.workspaceId = state.activeWorkspaceId;
      el.runTerminalMonitorStop.dataset.conversationId = state.activeConversationId;
    }
  }

  function renderQueueTray() {
    if (!el.queueTray || !el.queueTrayList) {
      return;
    }
    if (!state.activeWorkspaceId || !state.activeConversationId || state.activeDraftWorkspaceId) {
      el.queueTray.classList.add("hidden");
      return;
    }

    var wsId = state.activeWorkspaceId;
    var convId = state.activeConversationId;
    var stats = activeConversationQueueStats();
    var isEditingHere = isQueueEditForConversation(wsId, convId);
    var showTray = stats.pending > 0 || isEditingHere;
    if (!showTray) {
      el.queueTray.classList.add("hidden");
      return;
    }

    var queueKey = queueConversationKey(wsId, convId);
    var isLoading = !!state.queueItemsLoadingByConversation[queueKey];
    var fetchedAt = Number(state.queueItemsFetchedAtByConversation[queueKey] || 0);
    var staleMs = stats.running ? 900 : 1600;
    if (!isLoading && (!fetchedAt || Date.now() - fetchedAt > staleMs)) {
      loadQueueItems(wsId, convId, { minIntervalMs: staleMs }).then(function () {
        renderUi();
      }).catch(function () {
        return null;
      });
    }

    var queueItems = queueItemsForConversation(wsId, convId);
    var html = "";
    if (!queueItems.length && stats.pending > 0) {
      html += "<div class='queue-item'><div class='queue-item-main'><p class='queue-item-text'>Loading queued messages…</p></div></div>";
    }
    for (var i = 0; i < queueItems.length; i += 1) {
      var queueItem = queueItems[i] || {};
      var itemId = String(queueItem.id || "");
      if (!itemId) {
        continue;
      }
      var editingThis = isEditingHere && String(state.queueEdit.itemId || "") === itemId;
      if (editingThis) {
        var savingAttr = state.queueEdit.saving ? " disabled" : "";
        html += "<div class='queue-item'>";
        html += "<div class='queue-edit-wrap'>";
        html += "<p class='queue-item-meta'>" + escHtml(queueItemMetaLabel(queueItem, i)) + "</p>";
        html += "<textarea class='queue-edit-input' data-action='queue-edit-input' data-queue-item-id='" + escAttr(itemId) + "'>" + escHtml(state.queueEdit.draftText || "") + "</textarea>";
        html += "<div class='queue-edit-actions'>";
        html += "<button type='button' class='queue-btn' data-action='queue-edit-save' data-queue-item-id='" + escAttr(itemId) + "'" + savingAttr + ">Save</button>";
        html += "<button type='button' class='queue-btn' data-action='queue-edit-cancel' data-queue-item-id='" + escAttr(itemId) + "'" + savingAttr + ">Cancel</button>";
        html += "</div>";
        html += "</div>";
        html += "</div>";
      } else {
        html += "<div class='queue-item'>";
        html += "<div class='queue-item-main'>";
        html += "<p class='queue-item-text'>" + escHtml(queueItemPreview(queueItem.prompt || "", 240)) + "</p>";
        html += "<p class='queue-item-meta'>" + escHtml(queueItemMetaLabel(queueItem, i)) + "</p>";
        html += "</div>";
        html += "<div class='queue-item-actions'>";
        html += "<button type='button' class='queue-btn' data-action='queue-steer-item' data-queue-item-id='" + escAttr(itemId) + "'>Steer</button>";
        html += "<button type='button' class='queue-btn' data-action='queue-edit-item' data-queue-item-id='" + escAttr(itemId) + "'>Edit</button>";
        html += "<button type='button' class='queue-btn queue-trash' data-action='queue-trash-item' data-queue-item-id='" + escAttr(itemId) + "' aria-label='Delete queued message' title='Delete queued message'>&times;</button>";
        html += "</div>";
        html += "</div>";
      }
    }

    if (isConversationQueueBlockedByEdit(wsId, convId)) {
      html += "<p class='queue-paused-note'>Queue paused while editing the next queued message.</p>";
    }
    el.queueTrayList.innerHTML = html;
    el.queueTray.classList.remove("hidden");
  }

  function renderBranchMenu() {
    if (!el.branchMenuList || !el.branchCreateForm) {
      return;
    }
    var workspaceId = state.activeWorkspaceId;
    var gitState = activeGitState();

    if (!workspaceId) {
      el.branchMenuList.innerHTML = "<p class='empty-state'>Select a project first.</p>";
      el.branchCreateForm.classList.add("hidden");
      if (el.branchCreateSubmit) {
        el.branchCreateSubmit.disabled = true;
      }
      return;
    }

    if (!gitState.is_repo) {
      el.branchMenuList.innerHTML = "<button type='button' data-branch-action='create-repo'>Create repo</button>";
      el.branchCreateForm.classList.add("hidden");
      if (el.branchCreateSubmit) {
        el.branchCreateSubmit.disabled = true;
      }
      return;
    }
    el.branchCreateForm.classList.remove("hidden");
    if (el.branchCreateSubmit) {
      el.branchCreateSubmit.disabled = trim(el.branchCreateInput ? el.branchCreateInput.value : "") === "";
    }

    var branches = state.branchesByWorkspace[workspaceId] || [];
    if (!branches.length) {
      if (gitState.branch) {
        el.branchMenuList.innerHTML = "<button type='button' data-branch-select='" + escHtml(gitState.branch) + "'>" + escHtml(gitState.branch + " *") + "</button>";
      } else {
        el.branchMenuList.innerHTML = "<p class='empty-state'>No branches found.</p>";
      }
      return;
    }

    var html = "";
    for (var i = 0; i < branches.length; i += 1) {
      var branch = branches[i];
      var currentMark = branch.current ? " *" : "";
      html += "<button type='button' data-branch-select='" + escHtml(branch.name) + "'>" + escHtml(branch.name + currentMark) + "</button>";
    }

    el.branchMenuList.innerHTML = html;
  }

  function renderPermissionsButton() {
    if (!el.permissionsMenuBtn) {
      return;
    }
    var label = permissionModeLabel(state.permissionMode);
    el.permissionsMenuBtn.innerHTML =
      "<span class='menu-icon mono-icon' aria-hidden='true'>" + permissionModeIconMarkup(state.permissionMode) + "</span><span>" + escHtml(label) + "</span>";
    el.permissionsMenuBtn.title = label;
    renderPermissionModeMenu();
    renderCommandExecMenu();
    renderPermissionToggles();
  }

  function renderPermissionModeMenu() {
    if (!el.permissionsMenu) {
      return;
    }
    var items = el.permissionsMenu.querySelectorAll("button[data-permission]");
    for (var i = 0; i < items.length; i += 1) {
      var mode = String(items[i].getAttribute("data-permission") || "");
      items[i].classList.toggle("active", mode === state.permissionMode);
    }
  }

  function renderCommandExecMenu() {
    if (!el.permissionsMenu) {
      return;
    }
    var items = el.permissionsMenu.querySelectorAll("button[data-command-exec]");
    for (var i = 0; i < items.length; i += 1) {
      var mode = items[i].getAttribute("data-command-exec");
      items[i].classList.toggle("active", mode === state.commandExecMode);
    }
  }

  function renderPermissionToggles() {
    normalizePermissionToggles();

    if (el.networkToggleBtn) {
      el.networkToggleBtn.classList.toggle("on", !!state.networkAccess);
      el.networkToggleBtn.setAttribute("aria-pressed", state.networkAccess ? "true" : "false");
    }
    if (el.webToggleBtn) {
      el.webToggleBtn.classList.toggle("on", !!state.webAccess);
      el.webToggleBtn.setAttribute("aria-pressed", state.webAccess ? "true" : "false");
      el.webToggleBtn.classList.toggle("disabled", !state.networkAccess);
      el.webToggleBtn.disabled = !state.networkAccess;
    }
  }

  function renderAttachmentStrip() {
    if (!el.attachmentStrip) {
      return;
    }

    if (!state.pendingAttachments.length) {
      el.attachmentStrip.classList.add("hidden");
      el.attachmentStrip.innerHTML = "";
      return;
    }

    var html = "";
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      var attachment = state.pendingAttachments[i];
      var preview = attachment.previewUrl || "";
      var kind = attachment.kind || "file";
      html += "<div class='attachment-chip' data-action='preview-attachment' data-attachment-id='" + escAttr(attachment.id) + "' role='button' tabindex='0'>";
      html += "<button type='button' class='attachment-remove' data-action='remove-attachment' data-attachment-id='" + escAttr(attachment.id) + "' aria-label='Remove attachment'>&times;</button>";
      html += "<div class='attachment-thumb'>";
      if (kind === "image" && preview) {
        html += "<img src='" + escAttr(preview) + "' alt='" + escAttr(attachment.name || "image attachment") + "' />";
      } else if (kind === "text") {
        html += "<span>Text</span>";
      } else if (kind === "document") {
        html += "<span>PDF</span>";
      } else {
        html += "<span>File</span>";
      }
      html += "</div>";
      html += "<div class='attachment-name'>" + escHtml(attachment.name || "attachment") + "</div>";
      html += "<div class='attachment-meta'>" + escHtml(formatBytes(attachment.size || 0)) + "</div>";
      html += "</div>";
    }

    el.attachmentStrip.innerHTML = html;
    el.attachmentStrip.classList.remove("hidden");
  }

  function renderToolbarGit() {
    if (!el.branchMenuBtn || !el.commitMainBtn || !el.changesBtn) {
      return;
    }
    var gitState = activeGitState();

    if (!state.activeWorkspaceId) {
      el.branchMenuBtn.textContent = "No repo";
      el.branchMenuBtn.title = "Select a project first";
      el.commitMainBtn.disabled = true;
      if (el.commitMenuBtn) {
        el.commitMenuBtn.disabled = true;
      }
      el.changesBtn.innerHTML = gitDeltaMarkup(0, 0);
      return;
    }

    if (!gitState.is_repo) {
      el.branchMenuBtn.textContent = "Create repo";
      el.branchMenuBtn.title = "Initialize git repository";
      el.commitMainBtn.disabled = true;
      if (el.commitMenuBtn) {
        el.commitMenuBtn.disabled = true;
      }
      el.changesBtn.innerHTML = gitDeltaMarkup(0, 0);
      return;
    }

    el.branchMenuBtn.textContent = gitState.branch || "Branch";
    el.branchMenuBtn.title = "Git branch and repository";
    el.commitMainBtn.disabled = false;
    if (el.commitMenuBtn) {
      el.commitMenuBtn.disabled = false;
    }
    el.changesBtn.innerHTML = gitDeltaMarkup(gitState.added, gitState.deleted);
  }

  function renderChatHeader() {
    if (state.activeTriage) {
      el.chatTitle.textContent = "Triage Inbox";
      return;
    }
    if (!state.activeWorkspaceId) {
      el.chatTitle.textContent = "No thread";
      return;
    }

    if (state.activeDraftWorkspaceId) {
      el.chatTitle.textContent = "Draft thread";
      return;
    }

    if (state.activeConversation && state.activeConversation.title) {
      el.chatTitle.textContent = state.activeConversation.title;
      return;
    }

    el.chatTitle.textContent = "No thread";
  }

  function activeDecisionRequestInfo() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      return null;
    }
    var request = conversationDecisionRequest(state.activeConversation);
    if (!request) {
      var workspace = getWorkspaceById(state.activeWorkspaceId);
      var conversation = getConversationById(workspace, state.activeConversationId);
      request = conversationDecisionRequest(conversation);
    }
    if (!request) {
      return null;
    }
    var key = conversationReadKey(state.activeWorkspaceId, state.activeConversationId);
    var marker = key + "::" + request.question + "::" + request.options.join("||");
    return {
      workspaceId: state.activeWorkspaceId,
      conversationId: state.activeConversationId,
      key: key,
      marker: marker,
      request: request
    };
  }

  function activeApprovalRequestInfo() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      return null;
    }
    var workspace = getWorkspaceById(state.activeWorkspaceId);
    var conversation = getConversationById(workspace, state.activeConversationId);
    var request = conversationApprovalRequest(state.activeConversation);
    if (!request) {
      request = conversationApprovalRequest(conversation);
    }
    var awaitingApproval = false;
    if (conversation) {
      awaitingApproval = String(conversation.queue_last_status || "") === "awaiting_approval";
    }
    if (!awaitingApproval) {
      awaitingApproval = isAwaitingApprovalConversation(state.activeWorkspaceId, state.activeConversationId);
    }
    if (!awaitingApproval) {
      var events = runEventsForConversation(state.activeConversationId);
      for (var i = events.length - 1; i >= 0; i -= 1) {
        if (String(events[i].status || "") === "awaiting_approval") {
          awaitingApproval = true;
          break;
        }
      }
    }

    if (!request && awaitingApproval) {
      var inferredCommand = inferredApprovalCommandFromConversation();
      request = {
        command: inferredCommand,
        reason: ""
      };
    }
    if (!request) {
      return null;
    }
    return {
      workspaceId: state.activeWorkspaceId,
      conversationId: state.activeConversationId,
      request: request,
      hasCommand: !!trim(request.command || "")
    };
  }

  function latestUserPromptFromActiveConversation() {
    var messages = Array.isArray(state.activeConversation && state.activeConversation.messages)
      ? state.activeConversation.messages
      : [];
    for (var i = messages.length - 1; i >= 0; i -= 1) {
      var msg = messages[i] || {};
      if (String(msg.role || "") === "user") {
        var content = trim(String(msg.content || ""));
        if (content) {
          return content;
        }
      }
    }
    return "";
  }

  function latestAssistantMessageFromActiveConversation() {
    var messages = Array.isArray(state.activeConversation && state.activeConversation.messages)
      ? state.activeConversation.messages
      : [];
    for (var i = messages.length - 1; i >= 0; i -= 1) {
      var msg = messages[i] || {};
      if (String(msg.role || "") === "assistant") {
        var content = trim(String(msg.content || ""));
        if (content) {
          return content;
        }
      }
    }
    return "";
  }

  function inferredApprovalCommandFromConversation() {
    var text = latestAssistantMessageFromActiveConversation();
    if (!text) {
      return "";
    }

    var commandLine = text.match(/Command:\s*([^\n\r]+)/i);
    if (commandLine && commandLine[1]) {
      var candidate = trim(commandLine[1]).replace(/[.,;:]+$/, "");
      if (/^[./A-Za-z0-9_-]+$/.test(candidate)) {
        return candidate;
      }
    }

    var explicitPath = text.match(/\b(\.\/[A-Za-z0-9._/-]+)\b/);
    if (explicitPath && explicitPath[1]) {
      return explicitPath[1];
    }

    var shellFile = text.match(/\b([A-Za-z0-9._-]+\.sh)\b/);
    if (shellFile && shellFile[1]) {
      return "./" + shellFile[1];
    }

    return "";
  }

  function submitApprovalRequestAnswer(decision, scope) {
    var info = activeApprovalRequestInfo();
    if (!info) {
      return Promise.resolve();
    }
    var approvedDecision = String(decision || "") === "allow";
    var matchMode = trim(el.commandApprovalInlineMatchMode && el.commandApprovalInlineMatchMode.value) || "exact";
    var pattern = trim(el.commandApprovalInlinePattern && el.commandApprovalInlinePattern.value) || info.request.command;
    var commandText = String(info.request.command || "");
    var effectiveScope = scope;
    if (!trim(commandText)) {
      effectiveScope = "once";
    }
    return apiPost("approval_answer", {
      workspace_id: info.workspaceId,
      conversation_id: info.conversationId,
      command: commandText,
      decision: decision,
      scope: effectiveScope,
      match_mode: matchMode,
      pattern: pattern
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not submit approval.");
      }
      var queuedAfterApproval = queueNumber(response.queue_pending) > 0 || Number(response.queue_running || 0) > 0;
      if (approvedDecision && !queuedAfterApproval) {
        throw new Error("Approval was accepted, but no retry run was queued.");
      }
      if (approvedDecision) {
        startApprovalResumeWatch(info.workspaceId, info.conversationId);
      } else {
        stopApprovalResumeWatch();
      }
      applyQueueStateFromResponse(info.workspaceId, info.conversationId, response);
      setConversationQueueFields(info.workspaceId, info.conversationId, {
        approvalRequest: null
      });
      if (approvedDecision) {
        var approvalAnchor = 0;
        if (
          state.activeConversation &&
          state.activeWorkspaceId === info.workspaceId &&
          state.activeConversationId === info.conversationId &&
          Array.isArray(state.activeConversation.messages)
        ) {
          approvalAnchor = state.activeConversation.messages.length;
        }
        pushRunEvent(info.conversationId, {
          status: "approval_granted",
          approved_scope: effectiveScope || "once",
          approved_command: commandText,
          decision_hint: trim(String(response.decision_hint || "")),
          message_anchor: approvalAnchor,
          started_at: new Date().toISOString(),
          finished_at: new Date().toISOString()
        });
      }
      if (
        state.activeConversation &&
        state.activeWorkspaceId === info.workspaceId &&
        state.activeConversationId === info.conversationId
      ) {
        state.activeConversation.approval_request = null;
      }
      loadConversation({ timeoutMs: 6000 }).catch(function () {
        return null;
      });
      return null;
    }).then(function () {
      renderUi();
      state.queueWorkerActive = false;
      if (approvedDecision) {
        resumeConversationQueueNow(info.workspaceId, info.conversationId)
          .then(function (started) {
            if (!started) {
              kickQueueWorker();
            }
            return null;
          })
          .catch(function () {
            kickQueueWorker();
            return null;
          });
        return;
      }
      kickQueueWorker();
    });
  }

  function commandApprovalActionButtons() {
    return [
      el.commandApprovalInlineAllowOnce,
      el.commandApprovalInlineDenyOnce,
      el.commandApprovalInlineAllowRemember,
      el.commandApprovalInlineDenyRemember,
      el.commandApprovalAllowOnce,
      el.commandApprovalDenyOnce,
      el.commandApprovalAllowRemember,
      el.commandApprovalDenyRemember
    ];
  }

  function setApprovalAnswerUiPending(isPending, activeButton) {
    var buttons = commandApprovalActionButtons();
    for (var i = 0; i < buttons.length; i += 1) {
      var btn = buttons[i];
      if (!btn) {
        continue;
      }
      if (isPending) {
        if (!btn.hasAttribute("data-default-label")) {
          btn.setAttribute("data-default-label", btn.textContent || "");
        }
        btn.disabled = true;
      } else {
        btn.disabled = false;
        if (btn.hasAttribute("data-default-label")) {
          btn.textContent = btn.getAttribute("data-default-label") || "";
          btn.removeAttribute("data-default-label");
        }
      }
      btn.classList.toggle("approval-submit-pending", isPending && btn === activeButton);
    }
    if (activeButton && isPending) {
      activeButton.textContent = "Sending...";
    }
    if (el.commandApprovalInlineMatchMode) {
      el.commandApprovalInlineMatchMode.disabled = !!isPending;
    }
    if (el.commandApprovalInlinePattern) {
      el.commandApprovalInlinePattern.disabled = !!isPending;
    }
    if (el.commandApprovalInlineClose) {
      el.commandApprovalInlineClose.disabled = !!isPending;
    }
    if (el.commandApprovalInline) {
      el.commandApprovalInline.classList.toggle("is-submitting", !!isPending);
    }
    if (el.commandApprovalModal) {
      el.commandApprovalModal.classList.toggle("is-submitting", !!isPending);
    }
  }

  function releaseApprovalAnswerUiPendingIfAdvanced(workspaceId, conversationId, conversationEntry) {
    if (!approvalAnswerPending) {
      return;
    }
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return;
    }
    if (
      String(state.activeWorkspaceId || "") !== wsId ||
      String(state.activeConversationId || "") !== convId
    ) {
      return;
    }
    var entry = conversationEntry || {};
    var lastStatus = String(entry.queue_last_status || "");
    var hasApprovalRequest = !!normalizeApprovalRequest(entry.approval_request);
    if (lastStatus === "awaiting_approval" || hasApprovalRequest) {
      return;
    }
    approvalAnswerPending = false;
    setApprovalAnswerUiPending(false, null);
  }

  function submitApprovalRequestAnswerWithUi(decision, scope, sourceButton) {
    if (approvalAnswerPending) {
      return Promise.resolve();
    }
    var info = activeApprovalRequestInfo();
    if (String(decision || "") === "allow" && info) {
      startApprovalResumeWatch(info.workspaceId, info.conversationId);
    }
    approvalAnswerPending = true;
    setApprovalAnswerUiPending(true, sourceButton || null);
    return submitApprovalRequestAnswer(decision, scope).finally(function () {
      approvalAnswerPending = false;
      setApprovalAnswerUiPending(false, null);
      renderUi();
    });
  }

  function updateDecisionOtherVisibility() {
    if (!el.decisionRequestOptions || !el.decisionRequestOtherWrap || !el.decisionRequestOtherInput) {
      return;
    }
    var selected = el.decisionRequestOptions.querySelector("input[name='decision-request-choice']:checked");
    var isOther = !!(selected && selected.value === "other");
    el.decisionRequestOtherWrap.classList.toggle("hidden", !isOther);
    if (isOther) {
      el.decisionRequestOtherInput.focus();
    }
  }

  function selectedDecisionAnswer() {
    if (!el.decisionRequestOptions) {
      return "";
    }
    var selected = el.decisionRequestOptions.querySelector("input[name='decision-request-choice']:checked");
    if (!selected) {
      return "";
    }
    if (selected.value === "other") {
      return trim(el.decisionRequestOtherInput && el.decisionRequestOtherInput.value || "");
    }
    return trim(selected.getAttribute("data-choice") || "");
  }

  function submitDecisionRequest() {
    var info = activeDecisionRequestInfo();
    if (!info) {
      return Promise.resolve();
    }
    var answer = selectedDecisionAnswer();
    if (!answer) {
      return Promise.reject(new Error("Choose an option or type an Other answer."));
    }
    if (el.decisionRequestSubmit) {
      el.decisionRequestSubmit.disabled = true;
    }
    return apiPost("decision_answer", {
      workspace_id: info.workspaceId,
      conversation_id: info.conversationId,
      answer: answer
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not submit decision.");
      }
      state.decisionInlineDismissedKey = "";
      applyQueueStateFromResponse(info.workspaceId, info.conversationId, response);
      setConversationDecisionRequest(info.workspaceId, info.conversationId, response.decision_request || null);
      if (
        state.activeConversation &&
        state.activeWorkspaceId === info.workspaceId &&
        state.activeConversationId === info.conversationId
      ) {
        state.activeConversation.decision_request = normalizeDecisionRequest(response.decision_request);
      }
      loadConversation({ timeoutMs: 6000 }).catch(function () {
        return null;
      });
      return null;
    }).then(function () {
      renderUi();
      kickQueueWorker();
    }).finally(function () {
      if (el.decisionRequestSubmit) {
        el.decisionRequestSubmit.disabled = false;
      }
    });
  }

  function renderDecisionRequestInline() {
    if (
      !el.decisionRequestInline ||
      !el.decisionRequestInlineQuestion ||
      !el.decisionRequestOptions
    ) {
      return;
    }
    var info = activeDecisionRequestInfo();
    if (!info) {
      el.decisionRequestInline.classList.add("hidden");
      return;
    }
    if (state.decisionInlineDismissedKey === info.marker) {
      el.decisionRequestInline.classList.add("hidden");
      return;
    }

    var options = Array.isArray(info.request.options) ? info.request.options : [];
    var optionsMarkup = "";
    for (var i = 0; i < options.length; i += 1) {
      optionsMarkup += "<label class='decision-option'><input type='radio' name='decision-request-choice' value='choice-" + String(i) + "' data-choice='" + escAttr(options[i]) + "'" + (i === 0 ? " checked" : "") + "><span class='decision-option-index'>" + String(i + 1) + ".</span><span class='decision-option-text'>" + escHtml(options[i]) + "</span></label>";
    }
    optionsMarkup += "<label class='decision-option'><input type='radio' name='decision-request-choice' value='other'><span class='decision-option-index'>" + String(options.length + 1) + ".</span><span class='decision-option-text'>Other</span></label>";

    el.decisionRequestInlineQuestion.textContent = info.request.question;
    el.decisionRequestOptions.innerHTML = optionsMarkup;
    if (el.decisionRequestOtherInput) {
      el.decisionRequestOtherInput.value = "";
    }
    if (el.decisionRequestInline) {
      el.decisionRequestInline.dataset.marker = info.marker;
    }
    updateDecisionOtherVisibility();
    el.decisionRequestInline.classList.remove("hidden");
  }

  function renderCommandApprovalInline() {
    if (
      !el.commandApprovalInline ||
      !el.commandApprovalInlineAllowOnce ||
      !el.commandApprovalInlineDenyOnce ||
      !el.commandApprovalInlineAllowRemember ||
      !el.commandApprovalInlineDenyRemember
    ) {
      return;
    }
    if (pendingCommandApproval || approvalAnswerPending) {
      return;
    }
    var info = activeApprovalRequestInfo();
    if (!info) {
      el.commandApprovalInline.classList.add("hidden");
      return;
    }
    if (el.commandApprovalInlineText) {
      if (!info.hasCommand) {
        el.commandApprovalInlineText.textContent = "A command approval is pending, but command details were unavailable. You can allow once to retry or deny once to cancel.";
      } else {
        el.commandApprovalInlineText.textContent = info.request.reason
          ? "Agent requested a command (" + info.request.reason + ")."
          : "Agent requested command execution approval.";
      }
    }
    if (el.commandApprovalInlineCommand) {
      el.commandApprovalInlineCommand.textContent = info.hasCommand ? info.request.command : "(Command unavailable)";
    }
    if (el.commandApprovalInlineMatchMode) {
      el.commandApprovalInlineMatchMode.value = "exact";
      el.commandApprovalInlineMatchMode.disabled = !info.hasCommand;
    }
    if (el.commandApprovalInlinePattern) {
      el.commandApprovalInlinePattern.value = info.hasCommand ? defaultCommandRulePattern(info.request.command) : "";
      el.commandApprovalInlinePattern.disabled = !info.hasCommand;
    }
    el.commandApprovalInlineAllowOnce.onclick = function () {
      submitApprovalRequestAnswerWithUi("allow", "once", el.commandApprovalInlineAllowOnce).catch(showError);
    };
    el.commandApprovalInlineDenyOnce.onclick = function () {
      submitApprovalRequestAnswerWithUi("deny", "once", el.commandApprovalInlineDenyOnce).catch(showError);
    };
    el.commandApprovalInlineAllowRemember.onclick = function () {
      submitApprovalRequestAnswerWithUi("allow", "remember", el.commandApprovalInlineAllowRemember).catch(showError);
    };
    el.commandApprovalInlineDenyRemember.onclick = function () {
      submitApprovalRequestAnswerWithUi("deny", "remember", el.commandApprovalInlineDenyRemember).catch(showError);
    };
    el.commandApprovalInlineAllowRemember.disabled = !info.hasCommand;
    el.commandApprovalInlineDenyRemember.disabled = !info.hasCommand;
    if (el.commandApprovalInlineClose) {
      el.commandApprovalInlineClose.onclick = function () {
        el.commandApprovalInline.classList.add("hidden");
      };
    }
    el.commandApprovalInline.classList.remove("hidden");
  }

  function basename(pathText) {
    var clean = trim(String(pathText || "")).replace(/[\\/]+$/, "");
    if (!clean) {
      return "";
    }
    var idx = Math.max(clean.lastIndexOf("/"), clean.lastIndexOf("\\"));
    if (idx < 0) {
      return clean;
    }
    return clean.slice(idx + 1);
  }

  function openTargetLabel(target) {
    if (target === "terminal") {
      return "Terminal";
    }
    if (target === "textmate") {
      return "TextMate";
    }
    return "Finder";
  }

  function firstOpenTargetFromMenu() {
    if (!el.openMenu) {
      return "finder";
    }
    var first = el.openMenu.querySelector("button[data-open-target]");
    if (!first) {
      return "finder";
    }
    return String(first.getAttribute("data-open-target") || "finder");
  }

  function normalizedOpenTarget(target) {
    var value = String(target || "");
    if (value === "finder" || value === "terminal" || value === "textmate") {
      return value;
    }
    return firstOpenTargetFromMenu();
  }

  function openTargetIconMarkup(target) {
    var finderIcon = state.appIcons && state.appIcons.finder ? String(state.appIcons.finder) : "";
    var textmateIcon = state.appIcons && state.appIcons.textmate ? String(state.appIcons.textmate) : "";
    if (target === "terminal") {
      return "<span class='btn-icon app-icon terminal-app-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none'><rect x='1.2' y='2' width='13.6' height='12' rx='2.2' fill='#181B2A' stroke='#454A66' stroke-width='1'></rect><path d='M4 6.1l2 1.9L4 9.9' stroke='#D8DEFF' stroke-width='1.2' stroke-linecap='round' stroke-linejoin='round'></path><path d='M7.8 10h4.2' stroke='#D8DEFF' stroke-width='1.2' stroke-linecap='round'></path></svg></span>";
    }
    if (target === "textmate") {
      if (textmateIcon) {
        return "<span class='btn-icon app-icon textmate-icon real-app-icon' aria-hidden='true'><img class='app-icon-img' src='" + escAttr(textmateIcon) + "' alt=''></span>";
      }
      return "<span class='btn-icon app-icon textmate-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none'><circle cx='8' cy='8' r='6.3' fill='#F5ECFF' stroke='#A669D8' stroke-width='1'></circle><path d='M8 3.2l1.2 2.2 2.3-.8-.9 2.2 2.2 1.2-2.2 1.2.9 2.2-2.3-.8L8 12.8l-1.2-2.2-2.3.8.9-2.2L3.2 8l2.2-1.2-.9-2.2 2.3.8L8 3.2z' fill='#B84FE8'></path></svg></span>";
    }
    if (finderIcon) {
      return "<span class='btn-icon app-icon finder-icon real-app-icon' aria-hidden='true'><img class='app-icon-img' src='" + escAttr(finderIcon) + "' alt=''></span>";
    }
    return "<span class='btn-icon app-icon finder-icon' aria-hidden='true'></span>";
  }

  function renderOpenMenuIcons() {
    function setMenuIcon(target, dataUri) {
      var button = el.openMenu ? el.openMenu.querySelector("button[data-open-target='" + target + "']") : null;
      if (!button) {
        return;
      }
      var host = button.querySelector(".app-icon");
      if (!host) {
        return;
      }
      if (!dataUri) {
        host.classList.remove("real-app-icon");
        host.innerHTML = "";
        return;
      }
      host.classList.add("real-app-icon");
      host.innerHTML = "<img class='app-icon-img' src='" + escAttr(dataUri) + "' alt=''>";
    }

    setMenuIcon("finder", state.appIcons.finder || "");
    setMenuIcon("textmate", state.appIcons.textmate || "");
  }

  function commitActionIconMarkup(action) {
    if (action === "push") {
      return "<span class='btn-icon' aria-hidden='true'>&#10548;</span>";
    }
    if (action === "commit-push") {
      return "<span class='btn-icon' aria-hidden='true'>&#10549;</span>";
    }
    return "<span class='btn-icon' aria-hidden='true'>&#10227;</span>";
  }

  function renderOpenButton() {
    if (!el.openMainBtn || !el.openMenuBtn) {
      return;
    }
    var ws = activeWorkspace();
    var target = normalizedOpenTarget(state.lastOpenTarget);
    state.lastOpenTarget = target;
    var label = "Open";
    if (!ws) {
      el.openMainBtn.innerHTML = openTargetIconMarkup(target) + "<span class='btn-label'>" + escHtml(label) + "</span>";
      el.openMainBtn.title = "";
      el.openMainBtn.disabled = true;
      el.openMenuBtn.disabled = true;
      return;
    }
    el.openMainBtn.innerHTML = openTargetIconMarkup(target) + "<span class='btn-label'>" + escHtml(label) + "</span>";
    el.openMainBtn.title = ws.path || "";
    el.openMainBtn.disabled = false;
    el.openMenuBtn.disabled = false;
    if (el.openMenu) {
      var openButtons = el.openMenu.querySelectorAll("button[data-open-target]");
      for (var i = 0; i < openButtons.length; i += 1) {
        var openTarget = openButtons[i].getAttribute("data-open-target");
        openButtons[i].classList.toggle("active", openTarget === target);
      }
    }
  }

  function commitActionLabel(action) {
    if (action === "push") {
      return "Push";
    }
    if (action === "commit-push") {
      return "Commit & Push";
    }
    return "Commit";
  }

  function renderCommitButton() {
    if (!el.commitMainBtn) {
      return;
    }
    var ws = activeWorkspace();
    var gitState = activeGitState();
    var commitEnabled = !!ws;
    var action = state.lastCommitAction || "commit";
    el.commitMainBtn.innerHTML =
      commitActionIconMarkup(action) +
      "<span class='btn-label'>" + escHtml(commitActionLabel(action)) + "</span>";
    el.commitMainBtn.disabled = !commitEnabled;
    if (el.commitMenuBtn) {
      el.commitMenuBtn.disabled = !commitEnabled;
    }
    if (!commitEnabled && el.commitMenu && !el.commitMenu.classList.contains("hidden")) {
      el.commitMenu.classList.add("hidden");
    }
    if (!ws) {
      el.commitMainBtn.title = "Select a project first";
    } else if (gitState && gitState.is_repo) {
      el.commitMainBtn.title = "Primary commit action";
    } else {
      el.commitMainBtn.title = "No repo yet: click to create one";
    }
    if (el.commitMenuBtn) {
      el.commitMenuBtn.title = commitEnabled ? "Choose commit action" : "Select a project first";
    }
    if (el.commitMenu) {
      var commitButtons = el.commitMenu.querySelectorAll("button[data-commit-action]");
      for (var i = 0; i < commitButtons.length; i += 1) {
        var commitAction = commitButtons[i].getAttribute("data-commit-action");
        commitButtons[i].classList.toggle("active", commitAction === action);
        commitButtons[i].disabled = !ws;
      }
    }
  }

  function renderWorkspacePathWidget() {
    if (!el.workspacePathWidget) {
      return;
    }
    var ws = activeWorkspace();
    if (!ws || !ws.path) {
      el.workspacePathWidget.classList.add("hidden");
      el.workspacePathWidget.innerHTML = "";
      el.workspacePathWidget.title = "";
      el.workspacePathWidget.setAttribute("data-tooltip", "No project selected");
      el.workspacePathWidget.setAttribute("aria-label", "No project selected");
      el.workspacePathWidget.disabled = true;
      return;
    }
    el.workspacePathWidget.classList.remove("hidden");
    el.workspacePathWidget.innerHTML =
      "<span class='path-widget-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><path d='M1.8 4.4h4.1l1.2 1.3h7.1v6.1c0 .9-.7 1.6-1.6 1.6H3.4c-.9 0-1.6-.7-1.6-1.6z'></path></svg></span>" +
      "<span class='path-widget-label'>" + escHtml(ws.path) + "</span>";
    el.workspacePathWidget.title = "Click to copy path. Double-click to open folder.";
    el.workspacePathWidget.setAttribute("data-tooltip", "Click to copy path. Double-click to open folder.");
    el.workspacePathWidget.setAttribute("aria-label", "Project path: " + ws.path);
    el.workspacePathWidget.disabled = false;
  }

  function updateToolbarCompaction() {
    if (!el.toolbar) {
      return;
    }
    function commitControlVisible() {
      if (!el.commitMainBtn || !el.commitMenuBtn) {
        return true;
      }
      var toolbarRect = el.toolbar.getBoundingClientRect();
      var mainRect = el.commitMainBtn.getBoundingClientRect();
      var menuRect = el.commitMenuBtn.getBoundingClientRect();
      return mainRect.left >= toolbarRect.left - 1 && menuRect.right <= toolbarRect.right + 1;
    }
    function fitsWithinToolbar() {
      return el.toolbar.scrollWidth <= el.toolbar.clientWidth + 1 && commitControlVisible();
    }
    var compactClasses = ["path-icon-only", "open-icon-only", "commit-icon-only"];
    var i = 0;
    for (i = 0; i < compactClasses.length; i += 1) {
      el.toolbar.classList.remove(compactClasses[i]);
    }
    for (i = 0; i < compactClasses.length; i += 1) {
      if (fitsWithinToolbar()) {
        break;
      }
      el.toolbar.classList.add(compactClasses[i]);
    }
  }

  function contextKFromCatalogEntry(entry) {
    var raw = entry && typeof entry.context_k !== "undefined" ? entry.context_k : "";
    var parsed = Number(raw);
    if (!isFinite(parsed) || parsed <= 0) {
      return 0;
    }
    return Math.round(parsed);
  }

  function normalizedModelKey(text) {
    return trim(String(text || "")).toLowerCase();
  }

  function baseModelKey(text) {
    var key = normalizedModelKey(text);
    if (!key) {
      return "";
    }
    return key.split(":")[0];
  }

  function modelContextFromCatalog(modelName) {
    var target = normalizedModelKey(modelName);
    if (!target || !Array.isArray(state.modelCatalog) || !state.modelCatalog.length) {
      return 0;
    }
    var targetBase = baseModelKey(target);
    for (var i = 0; i < state.modelCatalog.length; i += 1) {
      var entry = state.modelCatalog[i] || {};
      if (normalizedModelKey(entry.name) === target) {
        return contextKFromCatalogEntry(entry);
      }
    }
    for (var j = 0; j < state.modelCatalog.length; j += 1) {
      var entry2 = state.modelCatalog[j] || {};
      if (baseModelKey(entry2.name) === targetBase) {
        return contextKFromCatalogEntry(entry2);
      }
    }
    return 0;
  }

  function inferredModelContextK(modelName) {
    var model = normalizedModelKey(modelName);
    if (!model) {
      return 0;
    }
    var explicitK = model.match(/(?:^|[^0-9])(\d{1,4})\s*k(?:[^a-z0-9]|$)/i);
    if (explicitK && explicitK[1]) {
      var parsed = Number(explicitK[1]);
      if (isFinite(parsed) && parsed > 0) {
        return Math.round(parsed);
      }
    }
    if (model.indexOf("llama3.1:8b") >= 0) {
      return 128;
    }
    if (model.indexOf("deepseek-coder-v2:16b") >= 0 || model.indexOf("qwen2.5-coder:7b") >= 0) {
      return 32;
    }
    if (model.indexOf("starcoder2:7b") >= 0 || model.indexOf("codellama:13b") >= 0) {
      return 16;
    }
    if (model.indexOf("phi3:mini") >= 0 || model.indexOf("mistral:7b") >= 0) {
      return 8;
    }
    return 0;
  }

  function activeModelContextInfo(modelName) {
    var catalogK = modelContextFromCatalog(modelName);
    if (catalogK > 0) {
      return {
        contextK: catalogK,
        source: "catalog"
      };
    }
    var inferredK = inferredModelContextK(modelName);
    if (inferredK > 0) {
      return {
        contextK: inferredK,
        source: "inferred"
      };
    }
    return {
      contextK: 0,
      source: "unknown"
    };
  }

  function renderContextWindowStatus() {
    if (!el.contextWindowBtn) {
      return;
    }
    var model = activeModelName();
    if (!model) {
      state.contextWindowText = "Context window information will display here.";
      el.contextWindowBtn.classList.add("unavailable");
      el.contextWindowBtn.setAttribute("data-tooltip", state.contextWindowText);
      el.contextWindowBtn.title = state.contextWindowText;
      return;
    }
    var info = activeModelContextInfo(model);
    if (info.contextK > 0) {
      var contextLabel = String(info.contextK) + "k tokens";
      var sourceLabel = info.source === "catalog" ? "catalog metadata" : "model-name inference";
      state.contextWindowText = "Context window: " + contextLabel + " (" + sourceLabel + "). Auto compaction: enabled.";
      el.contextWindowBtn.classList.remove("unavailable");
    } else {
      state.contextWindowText = "Context window unknown for this model. Auto compaction remains enabled with conservative limits.";
      el.contextWindowBtn.classList.add("unavailable");
    }
    el.contextWindowBtn.setAttribute("data-tooltip", state.contextWindowText);
    el.contextWindowBtn.setAttribute("aria-label", "Context window status. " + state.contextWindowText);
    el.contextWindowBtn.title = state.contextWindowText;
  }

  function renderChat() {
    var conversationKey = String(state.activeWorkspaceId || "") + "::" + String(state.activeConversationId || "") + "::" + String(state.activeDraftWorkspaceId || "");
    var keyChanged = conversationKey !== state.chatLastKey;
    var prevScrollTop = el.chatLog ? el.chatLog.scrollTop : 0;
    var prevClientHeight = el.chatLog ? el.chatLog.clientHeight : 0;
    var prevScrollHeight = el.chatLog ? el.chatLog.scrollHeight : 0;
    var prevBottomOffset = Math.max(0, prevScrollHeight - prevScrollTop - prevClientHeight);
    var shouldAutoScroll = keyChanged || state.chatAutoScroll;
    snapshotRunThinkingPreviewScroll();

    if (state.activeTriage) {
      var triageCards = Array.isArray(state.triage && state.triage.cards) ? state.triage.cards : [];
      var triageViewHtml = "<section class='triage-main-view'><h3>Triage Inbox</h3>";
      triageViewHtml += "<p class='settings-hint'>Agent proposals awaiting decision. Cleanup is ephemeral and creates no persistent policy.</p>";
      if (!triageCards.length) {
        triageViewHtml += "<p class='empty-state'>No triage items right now.</p>";
      } else {
        triageViewHtml += "<div class='triage-main-actions'><button type='button' data-action='triage-cleanup'>Cleanup...</button><button type='button' data-action='triage-cleanup-directed'>Cleanup w/ prompt...</button></div>";
        for (var t = 0; t < triageCards.length; t += 1) {
          var triageCard = triageCards[t] || {};
          var triageCardId = String(triageCard.id || "");
          var triageSuppressOpen = triageCardId && String(state.openTriageSuppressProposalId || "") === triageCardId;
          triageViewHtml += "<article class='triage-main-card'>";
          triageViewHtml += "<p><strong>" + escHtml(triageCard.summary || "Proposal") + "</strong></p>";
          triageViewHtml += "<p class='settings-hint'>" + escHtml(multiAgentEscalationLabel(triageCard.escalation_class || "")) + " • " + escHtml(multiAgentTargetTypeLabel(triageCard.target_type || "")) + " • agent " + escHtml(triageCard.resident || "") + "</p>";
          triageViewHtml += "<p class='settings-hint'>" + escHtml(triageCard.rationale || "") + "</p>";
          triageViewHtml += "<div class='modal-actions'>";
          triageViewHtml += "<button type='button' data-action='triage-open-context' data-workspace-id='" + escAttr(triageCard.workspace_id || "") + "' data-conversation-id='" + escAttr(triageCard.conversation_id || "") + "' data-proposal-id='" + escAttr(triageCardId) + "'>Open thread</button>";
          triageViewHtml += "<button type='button' data-action='triage-decide' data-proposal-id='" + escAttr(triageCardId) + "'>Decide</button>";
          triageViewHtml += "<span class='menu-anchor triage-scope-anchor'>";
          triageViewHtml += "<button type='button' data-action='triage-suppress-open' data-proposal-id='" + escAttr(triageCardId) + "' aria-expanded='" + (triageSuppressOpen ? "true" : "false") + "'>Create filter...</button>";
          triageViewHtml += "<div class='floating-menu triage-scope-menu" + (triageSuppressOpen ? "" : " hidden") + "' data-triage-scope-menu='" + escAttr(triageCardId) + "'>";
          triageViewHtml += "<button type='button' data-action='triage-suppress-scope' data-proposal-id='" + escAttr(triageCardId) + "' data-scope='workspace'>This project</button>";
          triageViewHtml += "<button type='button' data-action='triage-suppress-scope' data-proposal-id='" + escAttr(triageCardId) + "' data-scope='global'>All projects</button>";
          triageViewHtml += "</div>";
          triageViewHtml += "</span>";
          triageViewHtml += "</div>";
          triageViewHtml += "</article>";
        }
      }
      triageViewHtml += "</section>";
      if (state.chatMarkupCache !== triageViewHtml) {
        el.chatLog.innerHTML = triageViewHtml;
        state.chatMarkupCache = triageViewHtml;
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    if (!state.activeWorkspaceId) {
      var emptyWorkspaceMarkup = "";
      if (!state.initialLoadComplete) {
        emptyWorkspaceMarkup = "<p class='empty-state'><span class='run-spinner' aria-hidden='true'></span> Loading threads...</p>";
      } else {
        emptyWorkspaceMarkup = "<p class='empty-state'>Select or add a project to begin.</p>";
      }
      if (state.chatMarkupCache !== emptyWorkspaceMarkup) {
        el.chatLog.innerHTML = emptyWorkspaceMarkup;
        state.chatMarkupCache = emptyWorkspaceMarkup;
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    var outgoingKey = activeOutgoingKey();
    var pendingOutgoing = pendingOutgoingList(outgoingKey);

    if (state.activeDraftWorkspaceId) {
      if (pendingOutgoing.length) {
        var draftPendingHtml = "";
        for (var d = 0; d < pendingOutgoing.length; d += 1) {
          var pendingDraft = pendingOutgoing[d] || {};
          draftPendingHtml += "<article class='msg user pending'><div class='msg-body'>" + escHtml(pendingDraft.content || "") + "</div><p class='msg-pending-line'><span class='run-spinner' aria-hidden='true'></span>Sending...</p></article>";
        }
        if (state.chatMarkupCache !== draftPendingHtml) {
          el.chatLog.innerHTML = draftPendingHtml;
          state.chatMarkupCache = draftPendingHtml;
        }
      } else {
        var draftHintMarkup = "<p class='empty-state draft-create-hint'>Send a message to create the thread.</p>";
        if (state.chatMarkupCache !== draftHintMarkup) {
          el.chatLog.innerHTML = draftHintMarkup;
          state.chatMarkupCache = draftHintMarkup;
        }
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    if (!state.activeConversationId || !state.activeConversation) {
      var noConversationMarkup = "<p class='empty-state'>Select a thread or click + beside a project to start a draft.</p>";
      if (state.chatMarkupCache !== noConversationMarkup) {
        el.chatLog.innerHTML = noConversationMarkup;
        state.chatMarkupCache = noConversationMarkup;
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    var messages = Array.isArray(state.activeConversation.messages) ? state.activeConversation.messages : [];
    healRunningEventsForConversationFromSummary(state.activeWorkspaceId, state.activeConversationId);
    var events = runEventsForConversation(state.activeConversationId);

    if (!messages.length && !events.length && !pendingOutgoing.length) {
      var queueStats = activeConversationQueueStats();
      var runIsActiveHere = !!(
        queueStats.running ||
        queueStats.pending > 0 ||
        (
          state.busy &&
          String(state.runningWorkspaceId || "") === String(state.activeWorkspaceId || "") &&
          String(state.runningConversationId || "") === String(state.activeConversationId || "")
        )
      );
      if (runIsActiveHere) {
        var runningOnlyMarkup = "<article class='run-line-only'><p class='run-line running'><span class='run-spinner' aria-hidden='true'></span> <span class='meta-glimmer'>Thinking</span></p>";
        if (state.activeWorkspaceId && state.activeConversationId) {
          runningOnlyMarkup += "<p class='run-line subtle'>Working in this thread. Stream details will appear as events arrive.</p>";
        }
        runningOnlyMarkup += "</article>";
        if (state.chatMarkupCache !== runningOnlyMarkup) {
          el.chatLog.innerHTML = runningOnlyMarkup;
          state.chatMarkupCache = runningOnlyMarkup;
        }
      } else {
        var noMessagesMarkup = "<p class='empty-state'>No messages yet in this thread.</p>";
        if (state.chatMarkupCache !== noMessagesMarkup) {
          el.chatLog.innerHTML = noMessagesMarkup;
          state.chatMarkupCache = noMessagesMarkup;
        }
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    if (hasActiveChatSelection()) {
      updateChatJumpButton();
      return;
    }

    var html = "";
    var anchoredEventsByIndex = {};
    var tailEvents = [];
    for (var e = 0; e < events.length; e += 1) {
      var queuedEvent = events[e] || {};
      var eventStatus = String(queuedEvent.status || "");
      var anchorRaw = Number(queuedEvent.message_anchor);
      if (eventStatus === "approval_granted" && isFinite(anchorRaw)) {
        var anchorIndex = Math.max(0, Math.min(messages.length, Math.floor(anchorRaw)));
        if (!anchoredEventsByIndex[anchorIndex]) {
          anchoredEventsByIndex[anchorIndex] = [];
        }
        anchoredEventsByIndex[anchorIndex].push(queuedEvent);
      } else {
        tailEvents.push(queuedEvent);
      }
    }

    function renderAnchoredEventsAt(index) {
      var bucket = anchoredEventsByIndex[index];
      if (!bucket || !bucket.length) {
        return;
      }
      for (var bi = 0; bi < bucket.length; bi += 1) {
        html += renderRunEvent(bucket[bi], state.activeWorkspaceId, state.activeConversationId);
      }
    }

    function renderMessageAt(index) {
      var msg = messages[index] || {};
      var role = msg.role === "user" ? "user" : "assistant";
      if (role === "user") {
        html += "<article class='msg user'>";
        html += "<button type='button' class='msg-copy-btn' data-action='copy-user-message' data-copy-text='" + escAttr(msg.content || "") + "' aria-label='Copy message' title='Copy message'><span aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.35' stroke-linecap='round' stroke-linejoin='round'><rect x='5.4' y='5.3' width='7.2' height='7.2' rx='1.1'></rect><rect x='3.2' y='3.1' width='7.2' height='7.2' rx='1.1'></rect></svg></span></button>";
        html += "<div class='msg-body'>" + escHtml(msg.content || "") + "</div>";
        html += "</article>";
      } else {
        html += "<article class='msg assistant'><div class='msg-body'>" + escHtml(msg.content || "") + "</div></article>";
      }
    }

    renderAnchoredEventsAt(0);
    for (var m = 0; m < messages.length; m += 1) {
      renderMessageAt(m);
      renderAnchoredEventsAt(m + 1);
    }

    for (var p = 0; p < pendingOutgoing.length; p += 1) {
      var pending = pendingOutgoing[p] || {};
      html += "<article class='msg user pending'><div class='msg-body'>" + escHtml(pending.content || "") + "</div><p class='msg-pending-line'><span class='run-spinner' aria-hidden='true'></span>Sending...</p></article>";
    }

    for (var j = 0; j < tailEvents.length; j += 1) {
      var event = tailEvents[j] || {};
      html += renderRunEvent(event, state.activeWorkspaceId, state.activeConversationId);
    }

    if (state.chatMarkupCache !== html) {
      el.chatLog.innerHTML = html;
      state.chatMarkupCache = html;
    }
    var approvalInlineVisible = !!(
      el.commandApprovalInline &&
      !el.commandApprovalInline.classList.contains("hidden")
    );
    if (approvalInlineVisible && el.commandApprovalInline && el.chatLog) {
      if (el.commandApprovalInline.parentNode !== el.chatLog) {
        el.chatLog.appendChild(el.commandApprovalInline);
      }
      el.commandApprovalInline.classList.add("in-chat");
      shouldAutoScroll = true;
      state.chatAutoScroll = true;
    } else if (el.commandApprovalInline) {
      el.commandApprovalInline.classList.remove("in-chat");
    }
    if (shouldAutoScroll) {
      el.chatLog.scrollTop = el.chatLog.scrollHeight;
      state.chatAutoScroll = true;
    } else {
      var nextScrollTop = Math.max(0, el.chatLog.scrollHeight - el.chatLog.clientHeight - prevBottomOffset);
      el.chatLog.scrollTop = nextScrollTop;
      state.chatAutoScroll = isChatAtBottom();
    }
    state.chatLastKey = conversationKey;
    updateChatJumpButton();
    refreshRunningElapsedBadges();
    if (!liveRunTickTimer && el.chatLog && el.chatLog.querySelector(".run-line.running[data-started-at]")) {
      liveRunTickTimer = setInterval(function () {
        refreshRunningElapsedBadges();
      }, 1000);
    } else if (liveRunTickTimer && !state.busy && el.chatLog && !el.chatLog.querySelector(".run-line.running[data-started-at]")) {
      clearInterval(liveRunTickTimer);
      liveRunTickTimer = null;
    }
    syncRunThinkingPreviewScroll();
  }

  function hasActiveChatSelection() {
    if (!el.chatLog || !window.getSelection) {
      return false;
    }
    var sel = window.getSelection();
    if (!sel || sel.rangeCount < 1 || sel.isCollapsed) {
      return false;
    }
    var range = sel.getRangeAt(0);
    var container = range.commonAncestorContainer;
    if (!container) {
      return false;
    }
    var node = container.nodeType === 1 ? container : container.parentNode;
    return !!(node && el.chatLog.contains(node));
  }

  function formatDiff(diffText) {
    var raw = String(diffText || "");
    if (!trim(raw)) {
      return "<p class='empty-state'>No diff available.</p>";
    }

    var lines = raw.split(/\r?\n/);
    var html = "";
    for (var i = 0; i < lines.length; i += 1) {
      var line = lines[i];
      var cls = "";

      if (/^diff --git /.test(line) || /^\+\+\+ /.test(line) || /^--- /.test(line) || /^### /.test(line)) {
        cls = " file";
      } else if (/^@@ /.test(line)) {
        cls = " hunk";
      } else if (/^\+/.test(line) && !/^\+\+\+ /.test(line)) {
        cls = " add";
      } else if (/^-/.test(line) && !/^--- /.test(line)) {
        cls = " del";
      }

      html += "<span class='diff-line" + cls + "'>" + escHtml(line || " ") + "</span>";
    }
    return html;
  }

  function renderDiffView() {
    if (!el.diffView) {
      return;
    }
    el.diffView.innerHTML = formatDiff(state.diffText || "");
  }

  function renderTerminal() {
    if (!el.terminalOutput) {
      return;
    }
    if (el.terminalPanel) {
      el.terminalPanel.classList.toggle("busy", !!state.terminalBusy);
    }
    if (el.terminalCwd) {
      el.terminalCwd.textContent = state.terminalCwd || "Terminal";
    }
    var terminalText = String(state.terminalStreamText || "");
    if (state.terminalInputBuffer) {
      if (terminalText && terminalText.charAt(terminalText.length - 1) !== "\n") {
        terminalText += "\n";
      }
      terminalText += state.terminalInputBuffer;
    }
    el.terminalOutput.textContent = terminalText;
    el.terminalOutput.scrollTop = el.terminalOutput.scrollHeight;
  }

  function clampThreadsPaneWidth(width) {
    var minWidth = 220;
    var maxWidth = Math.min(620, Math.max(300, Math.floor(window.innerWidth * 0.66)));
    var value = Number(width || 0);
    if (!isFinite(value) || value <= 0) {
      value = 308;
    }
    if (value < minWidth) {
      value = minWidth;
    }
    if (value > maxWidth) {
      value = maxWidth;
    }
    return Math.round(value);
  }

  function clampDiffPaneWidth(width) {
    var shellWidth = (el.shell && el.shell.clientWidth) || window.innerWidth || 1200;
    var minWidth = 300;
    var maxWidth = Math.max(minWidth, Math.min(940, shellWidth - 260));
    var value = Number(width || 0);
    if (!isFinite(value) || value <= 0) {
      value = minWidth;
    }
    if (value < minWidth) {
      value = minWidth;
    }
    if (value > maxWidth) {
      value = maxWidth;
    }
    return Math.round(value);
  }

  function clampModelsPaneHeight(height) {
    var value = Number(height || 0);
    if (!isFinite(value) || value <= 0) {
      value = 300;
    }
    var minHeight = 140;
    var maxHeight = 560;
    if (el.workspacePanel) {
      var sidebarHeight = Number(el.workspacePanel.clientHeight || 0);
      var headEl = el.workspacePanel.querySelector(".workspace-sidebar-head");
      var footerEl = el.workspacePanel.querySelector(".workspace-sidebar-footer");
      var headHeight = headEl ? Number(headEl.offsetHeight || 0) : 0;
      var footerHeight = footerEl ? Number(footerEl.offsetHeight || 0) : 0;
      var minTreeHeight = 110;
      var dynamicMax = sidebarHeight - headHeight - footerHeight - minTreeHeight;
      if (isFinite(dynamicMax) && dynamicMax > 0) {
        maxHeight = Math.max(minHeight, Math.min(maxHeight, Math.floor(dynamicMax)));
      }
    }
    if (value < minHeight) {
      value = minHeight;
    }
    if (value > maxHeight) {
      value = maxHeight;
    }
    return Math.round(value);
  }

  function applyPaneWidths() {
    if (!el.shell) {
      return;
    }
    state.threadsPaneWidth = clampThreadsPaneWidth(state.threadsPaneWidth);
    state.diffPaneWidth = clampDiffPaneWidth(state.diffPaneWidth);
    state.modelsPaneHeight = clampModelsPaneHeight(state.modelsPaneHeight);
    el.shell.style.setProperty("--threads-width", state.threadsPaneWidth + "px");
    el.shell.style.setProperty("--diff-width", state.diffPaneWidth + "px");
    if (el.workspacePanel) {
      el.workspacePanel.style.setProperty("--models-pane-height", state.modelsPaneHeight + "px");
    }
  }

  function persistPaneWidths() {
    storageSet("artificer.threadsPaneWidth", String(state.threadsPaneWidth));
    storageSet("artificer.diffPaneWidth", String(state.diffPaneWidth));
    storageSet("artificer.modelsPaneHeight", String(state.modelsPaneHeight));
  }

  function stopPaneDrag() {
    if (!paneDragState) {
      return;
    }
    var draggedPaneType = String(paneDragState.type || "");
    paneDragState = null;
    if (document && document.body) {
      document.body.classList.remove("pane-resizing");
      document.body.classList.remove("pane-resizing-y");
    }
    if (draggedPaneType === "models") {
      suppressMenuCloseUntilMs = Date.now() + 280;
    }
    persistPaneWidths();
  }

  function onPaneDragMove(event) {
    if (!paneDragState || !el.shell) {
      return;
    }
    var shellRect = el.shell.getBoundingClientRect();
    if (paneDragState.type === "threads") {
      var nextThreads = event.clientX - shellRect.left;
      state.threadsPaneWidth = clampThreadsPaneWidth(nextThreads);
    } else if (paneDragState.type === "diff") {
      var nextDiff = shellRect.right - event.clientX;
      state.diffPaneWidth = clampDiffPaneWidth(nextDiff);
    } else if (paneDragState.type === "models") {
      if (!el.workspacePanel) {
        return;
      }
      var sidebarRect = el.workspacePanel.getBoundingClientRect();
      var footerEl = el.workspacePanel.querySelector(".workspace-sidebar-footer");
      var footerHeight = footerEl ? Number(footerEl.offsetHeight || 0) : 0;
      var nextModels = sidebarRect.bottom - event.clientY - footerHeight;
      state.modelsPaneHeight = clampModelsPaneHeight(nextModels);
    } else {
      return;
    }
    applyPaneWidths();
  }

  function startPaneDrag(type, event) {
    if (!el.shell) {
      return;
    }
    event.preventDefault();
    paneDragState = {
      type: type
    };
    if (document && document.body) {
      document.body.classList.add(type === "models" ? "pane-resizing-y" : "pane-resizing");
    }
  }

  function renderPanels() {
    if (!el.diffPanel || !el.terminalPanel || !el.shell) {
      return;
    }
    applyPaneWidths();
    if (state.diffOpen) {
      el.diffPanel.classList.remove("hidden");
      el.shell.classList.add("diff-open");
    } else {
      el.diffPanel.classList.add("hidden");
      el.shell.classList.remove("diff-open");
    }

    if (state.terminalOpen) {
      el.terminalPanel.classList.remove("hidden");
      el.shell.classList.add("terminal-open");
      if (
        state.activeWorkspaceId &&
        state.terminalSessionWorkspaceId &&
        state.terminalSessionWorkspaceId !== state.activeWorkspaceId
      ) {
        ensureTerminalSession().catch(function () {
          return null;
        });
      }
    } else {
      el.terminalPanel.classList.add("hidden");
      el.shell.classList.remove("terminal-open");
    }

    renderDiffView();
    renderTerminal();
  }

  function renderUi() {
    function safeStep(name, fn) {
      try {
        fn();
      } catch (err) {
        if (window && window.console && typeof window.console.error === "function") {
          window.console.error("Artificer render step failed:", name, err);
        }
      }
    }

    safeStep("ensureSelection", ensureSelection);
    safeStep("hydrateTooltips", hydrateTooltips);
    safeStep("renderWorkspaceTree", renderWorkspaceTree);
    safeStep("renderModelStatus", renderModelStatus);
    safeStep("renderThemePicker", renderThemePicker);
    safeStep("renderOrganizeMenu", renderOrganizeMenu);
    safeStep("renderModelPickerButton", renderModelPickerButton);
    safeStep("renderRunControls", renderRunControls);
    safeStep("renderRunButton", renderRunButton);
    safeStep("renderQueueControls", renderQueueControls);
    safeStep("renderOpenButton", renderOpenButton);
    safeStep("renderOpenMenuIcons", renderOpenMenuIcons);
    safeStep("renderCommitButton", renderCommitButton);
    safeStep("renderWorkspacePathWidget", renderWorkspacePathWidget);
    safeStep("renderModelsDialog", renderModelsDialog);
    safeStep("renderModelList.modelPicker", function () {
      renderModelListInto(el.modelPickerList, activeModelName());
    });
    safeStep("renderPermissionsButton", renderPermissionsButton);
    safeStep("renderContextWindowStatus", renderContextWindowStatus);
    safeStep("renderToolbarGit", renderToolbarGit);
    safeStep("renderBranchMenu", renderBranchMenu);
    safeStep("renderChatHeader", renderChatHeader);
    safeStep("renderDecisionRequestInline", renderDecisionRequestInline);
    safeStep("renderCommandApprovalInline", renderCommandApprovalInline);
    safeStep("renderChat", renderChat);
    safeStep("renderAttachmentStrip", renderAttachmentStrip);
    safeStep("renderRunTodoMonitor", renderRunTodoMonitor);
    safeStep("renderQueueTray", renderQueueTray);
    safeStep("renderRunTerminalMonitor", renderRunTerminalMonitor);
    safeStep("renderCommandRulesSettings", renderCommandRulesSettings);
    safeStep("renderModeRuntimeSettings", renderModeRuntimeSettings);
    safeStep("renderMultiAgentModal", renderMultiAgentModal);
    safeStep("renderPanels", renderPanels);
    safeStep("updateToolbarCompaction", updateToolbarCompaction);
    if (window && typeof window.requestAnimationFrame === "function") {
      window.requestAnimationFrame(updateToolbarCompaction);
    }
  }

  function saveSortMode(mode) {
    var next = mode === "created" ? "created" : "updated";
    state.sortMode = next;
    storageSet("artificer.workspaceSort", next);
  }

  function saveOrganizeMode(mode) {
    var next = mode === "chrono" ? "chrono" : "project";
    state.organizeMode = next;
    storageSet("artificer.organizeMode", next);
  }

  function saveOrganizeShow(mode) {
    var next = "all";
    if (mode === "relevant") {
      next = "relevant";
    } else if (mode === "running") {
      next = "running";
    }
    state.organizeShow = next;
    storageSet("artificer.organizeShow", next);
  }

  function renderOrganizeMenu() {
    if (!el.organizeMenu) {
      return;
    }
    var modeButtons = el.organizeMenu.querySelectorAll("button[data-organize-mode]");
    for (var i = 0; i < modeButtons.length; i += 1) {
      var modeValue = modeButtons[i].getAttribute("data-organize-mode");
      modeButtons[i].classList.toggle("active", modeValue === state.organizeMode);
    }

    var sortButtons = el.organizeMenu.querySelectorAll("button[data-organize-sort]");
    for (var j = 0; j < sortButtons.length; j += 1) {
      var sortValue = sortButtons[j].getAttribute("data-organize-sort");
      sortButtons[j].classList.toggle("active", sortValue === state.sortMode);
    }

    var showButtons = el.organizeMenu.querySelectorAll("button[data-organize-show]");
    for (var k = 0; k < showButtons.length; k += 1) {
      var showValue = showButtons[k].getAttribute("data-organize-show");
      showButtons[k].classList.toggle("active", showValue === state.organizeShow);
    }
  }

  function savePermissionMode(mode) {
    state.permissionMode = mode;
    storageSet("artificer.permissionMode", mode);
  }

  function saveCommandExecMode(mode) {
    var next = "ask-some";
    if (mode === "ask") {
      next = "ask-some";
    } else if (mode === "none" || mode === "ask-all" || mode === "ask-some" || mode === "all") {
      next = mode;
    }
    state.commandExecMode = next;
    storageSet("artificer.commandExecMode", next);
  }

  function syncCommandExecModeForWorkspace(workspaceId) {
    var wsId = trim(workspaceId);
    if (!wsId) {
      return Promise.resolve();
    }
    return apiGet("command_policy_get", { workspace_id: wsId })
      .then(function (response) {
        if (!response || !response.success) {
          return;
        }
        saveCommandExecMode(response.mode || "ask-some");
      })
      .catch(function () {
        return null;
      });
  }

  function setCommandExecMode(mode) {
    var next = mode;
    if (next === "ask") {
      next = "ask-some";
    }
    if (next !== "none" && next !== "ask-all" && next !== "ask-some" && next !== "all") {
      next = "ask-some";
    }
    if (next === "all") {
      var ok = window.confirm("Ask none will allow all agent commands without asking. Continue?");
      if (!ok) {
        return Promise.resolve(false);
      }
    }
    saveCommandExecMode(next);
    if (!state.activeWorkspaceId) {
      return Promise.resolve(true);
    }
    return apiPost("command_policy_set", {
      workspace_id: state.activeWorkspaceId,
      mode: next
    })
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Could not save command policy");
        }
        saveCommandExecMode(response.mode || next);
        return true;
      });
  }

  function saveAgentLoopEnabled(enabled) {
    state.agentLoopEnabled = !!enabled;
    storageSet("artificer.agentLoopEnabled", state.agentLoopEnabled ? "1" : "0");
  }

  function modeFromSlashCommand(commandText) {
    var value = String(commandText || "").toLowerCase().replace(/^\/+/, "");
    if (value === "chat") {
      return "chat";
    }
    if (value === "teacher" || value === "teach" || value === "learn" || value === "study" || value === "tutor") {
      return "teacher";
    }
    if (value === "task" || value === "programming" || value === "program" || value === "code" || value === "dev") {
      return "programming";
    }
    if (value === "report") {
      return "report";
    }
    if (
      value === "assistant" ||
      value === "autonomous" ||
      value === "autonomy" ||
      value === "endeavor" ||
      value === "endeavour"
    ) {
      return "assistant";
    }
    if (value === "auto" || value === "thinking" || value === "loop") {
      return "auto";
    }
    if (value === "instant" || value === "quick") {
      return "instant";
    }
    return "";
  }

  function normalizeDirectiveSkillId(skillId) {
    var value = trim(String(skillId || "")).toLowerCase();
    if (!value) {
      return "";
    }
    if (!/^[a-z][a-z0-9_-]*$/.test(value)) {
      return "";
    }
    return value;
  }

  function parsePromptExplicitSkillTags(promptText) {
    var text = String(promptText || "");
    if (!text) {
      return [];
    }
    var pattern = /\$([a-z][a-z0-9_-]*)\b/ig;
    var seen = {};
    var skills = [];
    var match = null;
    while ((match = pattern.exec(text))) {
      var normalized = normalizeDirectiveSkillId(match[1] || "");
      if (!normalized || seen[normalized]) {
        continue;
      }
      seen[normalized] = 1;
      skills.push(normalized);
      if (skills.length >= 12) {
        break;
      }
    }
    return skills;
  }

  function mergeSkillIdLists(firstList, secondList) {
    var merged = [];
    var seen = {};

    function append(list) {
      var source = Array.isArray(list) ? list : [];
      for (var i = 0; i < source.length; i += 1) {
        var normalized = normalizeDirectiveSkillId(source[i]);
        if (!normalized || seen[normalized]) {
          continue;
        }
        seen[normalized] = 1;
        merged.push(normalized);
        if (merged.length >= 18) {
          return;
        }
      }
    }

    append(firstList);
    append(secondList);
    return merged;
  }

  function parsePromptModeDirective(promptText) {
    var raw = String(promptText || "");
    var working = raw;
    var matchedMode = "";
    var matchedTag = "";
    var guard = 0;
    while (guard < 3) {
      var match = working.match(/^\s*\/([a-z][a-z0-9_-]*)\b[ \t]*/i);
      if (!match) {
        break;
      }
      var tag = "/" + String(match[1] || "").toLowerCase();
      var mappedMode = modeFromSlashCommand(tag);
      if (!mappedMode) {
        break;
      }
      matchedMode = mappedMode;
      matchedTag = tag;
      working = working.slice(match[0].length);
      guard += 1;
      if (!/^\s*\/[a-z]/i.test(working)) {
        break;
      }
    }
    return {
      mode: matchedMode,
      tag: matchedTag,
      skillIds: parsePromptExplicitSkillTags(working),
      prompt: trim(working),
      raw: raw
    };
  }

  function runtimeModeById(modeId) {
    var target = trim(String(modeId || ""));
    if (!target) {
      return null;
    }
    var runtime = normalizeModeRuntime(state.modeRuntime);
    var modes = Array.isArray(runtime.modes) ? runtime.modes : [];
    for (var i = 0; i < modes.length; i += 1) {
      var mode = modes[i] || {};
      if (String(mode.id || "") === target) {
        return mode;
      }
    }
    return null;
  }

  function normalizeAssistantModeId(modeId) {
    var value = trim(String(modeId || "")).toLowerCase();
    if (!value) {
      return "";
    }
    if (!/^[a-z0-9._-]+$/.test(value)) {
      return "";
    }
    var runtime = normalizeModeRuntime(state.modeRuntime);
    var modes = Array.isArray(runtime.modes) ? runtime.modes : [];
    if (!modes.length) {
      return value;
    }
    var mode = runtimeModeById(value);
    if (!mode) {
      return "";
    }
    return value;
  }

  function saveAssistantModeId(modeId) {
    var next = normalizeAssistantModeId(modeId);
    state.assistantModeId = next;
    storageSet("artificer.assistantModeId", next);
  }

  function reconcileAssistantModeId() {
    var next = normalizeAssistantModeId(state.assistantModeId);
    if (next === state.assistantModeId) {
      return;
    }
    state.assistantModeId = next;
    storageSet("artificer.assistantModeId", next);
  }

  function assistantModeLabel(modeId) {
    var mode = runtimeModeById(modeId);
    if (!mode) {
      return "";
    }
    return trim(String(mode.name || mode.id || ""));
  }

  function normalizeRunMode(mode) {
    var value = String(mode || "").toLowerCase();
    if (
      value !== "instant" &&
      value !== "auto" &&
      value !== "programming" &&
      value !== "chat" &&
      value !== "teacher" &&
      value !== "report" &&
      value !== "assistant"
    ) {
      value = "auto";
    }
    return value;
  }

  function runModeLabel(mode) {
    var value = normalizeRunMode(mode);
    if (value === "instant") {
      return "Instant";
    }
    if (value === "programming") {
      return "Programming";
    }
    if (value === "chat") {
      return "Chat";
    }
    if (value === "teacher") {
      return "Teacher";
    }
    if (value === "report") {
      return "Report";
    }
    if (value === "assistant") {
      var focusLabel = assistantModeLabel(state.assistantModeId);
      if (focusLabel) {
        return "Assistant - " + focusLabel;
      }
      return "Assistant";
    }
    return "Auto/Thinking";
  }

  function runModeDescription(mode) {
    var value = normalizeRunMode(mode);
    if (value === "instant") {
      return "Single-pass quick reply. Fastest turnaround.";
    }
    if (value === "programming") {
      return "Code-specialized loop with stronger execution and verification defaults. Inline tag: /task";
    }
    if (value === "chat") {
      return "Human conversation mode. Direct assistant-style responses. Inline tag: /chat";
    }
    if (value === "teacher") {
      return "Personalized teaching mode with learner modeling, curriculum sequencing, and spaced review prompts. Inline tag: /teacher";
    }
    if (value === "report") {
      return "Extended investigation mode that prioritizes evidence gathering and report-quality output. Inline tag: /report";
    }
    if (value === "assistant") {
      var focusMode = runtimeModeById(state.assistantModeId);
      if (focusMode) {
        return "Highest-autonomy mode with long-loop initiative. Focus mode: " + (focusMode.name || focusMode.id) + ". " + (focusMode.description || "");
      }
      return "Highest-autonomy mode with long-loop initiative within safety and approval constraints. Inline tag: /assistant";
    }
    return "Adaptive default. Balanced thinking loop for mixed tasks.";
  }

  function runModeDefaultProfile(mode) {
    var value = normalizeRunMode(mode);
    if (value === "instant") {
      return { advancedLoop: false, reasoning: "low", minIterations: 1, maxIterations: 2 };
    }
    if (value === "programming") {
      return { advancedLoop: true, reasoning: "high", minIterations: 6, maxIterations: 12 };
    }
    if (value === "chat") {
      return { advancedLoop: false, reasoning: "medium", minIterations: 1, maxIterations: 2 };
    }
    if (value === "teacher") {
      return { advancedLoop: true, reasoning: "high", minIterations: 6, maxIterations: 12 };
    }
    if (value === "report") {
      return { advancedLoop: true, reasoning: "high", minIterations: 8, maxIterations: 12 };
    }
    if (value === "assistant") {
      return { advancedLoop: true, reasoning: "extra-high", minIterations: 10, maxIterations: 12 };
    }
    return { advancedLoop: true, reasoning: "medium", minIterations: 2, maxIterations: 12 };
  }

  function reasoningRank(level) {
    if (level === "low") {
      return 1;
    }
    if (level === "high") {
      return 3;
    }
    if (level === "extra-high") {
      return 4;
    }
    return 2;
  }

  function saveRunMode(mode) {
    var next = normalizeRunMode(mode);
    var profile = runModeDefaultProfile(next);
    state.runMode = next;
    storageSet("artificer.runMode", next);
    saveAgentLoopEnabled(!!profile.advancedLoop);
    saveReasoningEffort(profile.reasoning);
  }

  function saveReasoningEffort(level) {
    var next = "medium";
    if (level === "low" || level === "medium" || level === "high" || level === "extra-high") {
      next = level;
    }
    state.reasoningEffort = next;
    storageSet("artificer.reasoningEffort", next);
  }

  function normalizeComputeBudget(value) {
    var next = String(value || "").toLowerCase();
    if (
      next !== "auto" &&
      next !== "quick" &&
      next !== "standard" &&
      next !== "long" &&
      next !== "until-complete"
    ) {
      next = "auto";
    }
    return next;
  }

  function saveComputeBudget(value) {
    var next = normalizeComputeBudget(value);
    state.computeBudget = next;
    storageSet("artificer.computeBudget", next);
  }

  function computeBudgetLabel(value) {
    var next = normalizeComputeBudget(value);
    if (next === "quick") {
      return "Instant";
    }
    if (next === "standard") {
      return "Standard";
    }
    if (next === "long") {
      return "Long-term";
    }
    if (next === "until-complete") {
      return "Until Complete";
    }
    return "Auto";
  }

  function computeBudgetRequestTimeoutMs(value, runPayload) {
    var budget = normalizeComputeBudget(value);
    if (budget === "quick") {
      return 10 * 60 * 1000;
    }
    if (budget === "standard") {
      return 25 * 60 * 1000;
    }
    if (budget === "long") {
      return 90 * 60 * 1000;
    }
    if (budget === "until-complete") {
      return 8 * 60 * 60 * 1000;
    }

    var timeoutMs = 20 * 60 * 1000;
    var maxIterations = Number(runPayload && runPayload.max_iterations ? runPayload.max_iterations : 0);
    var advancedLoop = String(runPayload && runPayload.advanced_loop ? runPayload.advanced_loop : "") === "1";
    var reasoning = String(runPayload && runPayload.reasoning_effort ? runPayload.reasoning_effort : "").toLowerCase();
    var promptText = String(runPayload && runPayload.prompt ? runPayload.prompt : "");
    var promptLower = promptText.toLowerCase();

    if (advancedLoop) {
      timeoutMs = Math.max(timeoutMs, 30 * 60 * 1000);
    }
    if (maxIterations >= 10) {
      timeoutMs = Math.max(timeoutMs, 36 * 60 * 1000);
    } else if (maxIterations >= 8) {
      timeoutMs = Math.max(timeoutMs, 30 * 60 * 1000);
    }
    if (reasoning === "high" || reasoning === "extra-high") {
      timeoutMs = Math.max(timeoutMs, 28 * 60 * 1000);
    }
    if (promptText.length > 900) {
      timeoutMs = Math.max(timeoutMs, 28 * 60 * 1000);
    }
    if (
      /godot|barnes[- ]?hut|checksum|deterministic replay|final[ -]?state|regression|self[- ]?tests?|gameplay|challenge|polish|interactiv|objective|score|combo|large[ -]?context|architecture|monorepo|migration|distributed|launch|business|compliance|operations|curriculum|lesson plan|spaced review|pedagog|learning model|tutor/.test(promptLower)
    ) {
      timeoutMs = Math.max(timeoutMs, 45 * 60 * 1000);
    }
    return timeoutMs;
  }

  function computeBudgetQueueWatchTimeoutMs(value) {
    var budget = normalizeComputeBudget(value);
    if (budget === "quick") {
      return 12 * 60 * 1000;
    }
    if (budget === "standard") {
      return 35 * 60 * 1000;
    }
    if (budget === "long") {
      return 2 * 60 * 60 * 1000;
    }
    if (budget === "until-complete") {
      return 10 * 60 * 60 * 1000;
    }
    return 45 * 60 * 1000;
  }

  function reasoningLabel(level) {
    if (level === "low") {
      return "Low";
    }
    if (level === "high") {
      return "High";
    }
    if (level === "extra-high") {
      return "Extra High";
    }
    return "Medium";
  }

  function reasoningIconMarkup() {
    return "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.35' stroke-linecap='round' stroke-linejoin='round'><path d='M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z'></path><path d='M6.3 5.8c-.6.2-.9.6-.9 1.1'></path><path d='M8 5.4v4.3'></path><path d='M9.8 5.9c.6.2.9.6.9 1.1'></path><path d='M6.4 8.6c.4.4 1 .6 1.6.6'></path><path d='M9.6 8.6c-.4.4-1 .6-1.6.6'></path></svg>";
  }

  function effectiveRunProfileForMode(modeValue) {
    var reasoningToIterations = {
      low: 2,
      medium: 4,
      high: 6,
      "extra-high": 8
    };
    var mode = normalizeRunMode(modeValue || state.runMode);
    var defaults = runModeDefaultProfile(mode);
    var reasoning = String(state.reasoningEffort || defaults.reasoning || "medium");
    if (reasoningRank(reasoning) < reasoningRank(defaults.reasoning)) {
      reasoning = defaults.reasoning;
    }
    var iterations = reasoningToIterations[reasoning] || 4;
    if (Number(defaults.minIterations || 0) > iterations) {
      iterations = Number(defaults.minIterations || iterations);
    }
    var maxIterations = Number(defaults.maxIterations || 0);
    if (maxIterations > 0 && iterations > maxIterations) {
      iterations = maxIterations;
    }
    var advancedLoop = !!defaults.advancedLoop;
    if (mode === "auto") {
      advancedLoop = !!state.agentLoopEnabled;
    }
    return {
      mode: mode,
      reasoning: reasoning,
      maxIterations: iterations,
      advancedLoop: advancedLoop,
      computeBudget: normalizeComputeBudget(state.computeBudget)
    };
  }

  function effectiveRunProfile() {
    return effectiveRunProfileForMode(state.runMode);
  }

  function saveNetworkAccess(enabled) {
    state.networkAccess = !!enabled;
    storageSet("artificer.networkAccess", state.networkAccess ? "1" : "0");
  }

  function saveWebAccess(enabled) {
    state.webAccess = !!enabled;
    storageSet("artificer.webAccess", state.webAccess ? "1" : "0");
  }

  function appendTerminalLine(line) {
    var next = state.terminalStreamText + String(line || "") + "\n";
    if (next.length > 180000) {
      next = next.slice(next.length - 180000);
    }
    state.terminalStreamText = next;
    renderTerminal();
  }

  function titleFromPrompt(promptText) {
    var directive = parsePromptModeDirective(promptText);
    var titleSource = trim(directive.prompt || promptText);
    var first = trim(String(titleSource || "").split(/\r?\n/)[0] || "");
    if (!first) {
      return "New Thread";
    }
    if (first.length > 52) {
      return first.slice(0, 49) + "...";
    }
    return first;
  }

  function clearDraftAutosaveTimer() {
    if (saveDraftTimer) {
      clearTimeout(saveDraftTimer);
      saveDraftTimer = null;
    }
  }

  function revokeAttachmentPreview(attachment) {
    if (attachment && attachment.previewUrl) {
      URL.revokeObjectURL(attachment.previewUrl);
    }
  }

  function clearPendingAttachments() {
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      revokeAttachmentPreview(state.pendingAttachments[i]);
    }
    state.pendingAttachments = [];
  }

  function resetComposerAttachments() {
    clearPendingAttachments();
    state.composerDragDepth = 0;
    setComposerDragActive(false);
    renderAttachmentStrip();
  }

  function removePendingAttachmentById(attachmentId) {
    var kept = [];
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      var attachment = state.pendingAttachments[i];
      if (attachment.id === attachmentId) {
        revokeAttachmentPreview(attachment);
      } else {
        kept.push(attachment);
      }
    }
    state.pendingAttachments = kept;
    renderAttachmentStrip();
  }

  function attachmentAlreadyQueued(file) {
    var name = String(file && file.name || "");
    var size = Number(file && file.size || 0);
    var lastModified = Number(file && file.lastModified || 0);
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      var attachment = state.pendingAttachments[i];
      if (attachment.name === name && Number(attachment.size || 0) === size && Number(attachment.lastModified || 0) === lastModified) {
        return true;
      }
    }
    return false;
  }

  function addComposerAttachment(file) {
    if (!file) {
      return;
    }

    if (attachmentAlreadyQueued(file)) {
      return;
    }

    var kind = attachmentKindForFile(file);
    if (!kind) {
      throw new Error("Unsupported file type for attachment: " + String(file.name || "file"));
    }

    var maxBytes = 15 * 1024 * 1024;
    if (Number(file.size || 0) > maxBytes) {
      throw new Error("Attachment too large: " + String(file.name || "file") + " (" + formatBytes(file.size) + "). Max 15 MB.");
    }

    var previewUrl = URL.createObjectURL(file);

    state.pendingAttachments.push({
      id: newClientAttachmentId(),
      file: file,
      name: String(file.name || "attachment"),
      mime: String(file.type || ""),
      size: Number(file.size || 0),
      lastModified: Number(file.lastModified || 0),
      kind: kind,
      previewUrl: previewUrl
    });
  }

  function addComposerFiles(fileList) {
    if (!fileList || !fileList.length) {
      return;
    }

    for (var i = 0; i < fileList.length; i += 1) {
      addComposerAttachment(fileList[i]);
    }
    renderAttachmentStrip();
  }

  function attachmentById(attachmentId) {
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      if (state.pendingAttachments[i].id === attachmentId) {
        return state.pendingAttachments[i];
      }
    }
    return null;
  }

  function openAttachmentPreview(attachmentId) {
    var attachment = attachmentById(attachmentId);
    if (!attachment || !attachment.previewUrl) {
      return;
    }
    window.open(attachment.previewUrl, "_blank", "noopener");
  }

  function fileToBase64(file) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () {
        var dataUrl = String(reader.result || "");
        var comma = dataUrl.indexOf(",");
        if (comma < 0) {
          reject(new Error("Could not read attachment data."));
          return;
        }
        resolve(dataUrl.slice(comma + 1));
      };
      reader.onerror = function () {
        reject(new Error("Could not read attachment: " + String(file && file.name || "file")));
      };
      reader.readAsDataURL(file);
    });
  }

  function uploadAttachment(workspaceId, conversationId, attachment) {
    return fileToBase64(attachment.file).then(function (encoded) {
      return apiPost("upload_attachment", {
        workspace_id: workspaceId,
        conversation_id: conversationId,
        name: attachment.name,
        mime: attachment.mime,
        data: encoded
      }).then(function (response) {
        if (!response.success || !response.attachment || !response.attachment.id) {
          throw new Error(response.error || "Failed to upload attachment");
        }
        return response.attachment;
      });
    });
  }

  function uploadPendingAttachments(workspaceId, conversationId) {
    if (!state.pendingAttachments.length) {
      return Promise.resolve([]);
    }

    var uploaded = [];
    var chain = Promise.resolve();
    for (var i = 0; i < state.pendingAttachments.length; i += 1) {
      (function (attachment) {
        chain = chain.then(function () {
          return uploadAttachment(workspaceId, conversationId, attachment).then(function (item) {
            uploaded.push(item);
          });
        });
      })(state.pendingAttachments[i]);
    }
    return chain.then(function () {
      return uploaded;
    });
  }

  function loadState(options) {
    var requestOptions = null;
    if (options && Number(options.timeoutMs) > 0) {
      requestOptions = { timeoutMs: Number(options.timeoutMs) };
    }
    return apiGet("state", {}, requestOptions).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load state");
      }
      state.workspaces = response.workspaces || [];
      state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
      state.triage = {
        count: String((response.triage && response.triage.count) || "0"),
        cards: Array.isArray(response.triage && response.triage.cards) ? response.triage.cards : []
      };
      state.multi_agentCatalog = response.multi_agent_catalog && typeof response.multi_agent_catalog === "object"
        ? response.multi_agent_catalog
        : { curated_residents: [], target_types: [], escalation_classes: [] };
      reconcileAssistantModeId();
      state.modeRuntimeError = "";
      for (var i = 0; i < state.workspaces.length; i += 1) {
        if (typeof state.workspaces[i].multi_agent_background_residents === "undefined") {
          state.workspaces[i].multi_agent_background_residents = "0";
        } else {
          state.workspaces[i].multi_agent_background_residents = String(state.workspaces[i].multi_agent_background_residents || "0");
        }
        if (!Array.isArray(state.workspaces[i].multi_agent_residents)) {
          state.workspaces[i].multi_agent_residents = [];
        }
        if (!Array.isArray(state.workspaces[i].multi_agent_unratified_amendments)) {
          state.workspaces[i].multi_agent_unratified_amendments = [];
        }
        if (!state.workspaces[i].multi_agent_toggles || typeof state.workspaces[i].multi_agent_toggles !== "object") {
          state.workspaces[i].multi_agent_toggles = {};
        }
        if (!Array.isArray(state.workspaces[i].conversations)) {
          state.workspaces[i].conversations = [];
        }
        for (var j = 0; j < state.workspaces[i].conversations.length; j += 1) {
          var conv = state.workspaces[i].conversations[j];
          if (typeof conv.created === "undefined" || conv.created === null || conv.created === "") {
            if (typeof conv.updated !== "undefined" && conv.updated !== null && conv.updated !== "") {
              conv.created = String(conv.updated);
            } else {
              conv.created = "0";
            }
          } else {
            conv.created = String(conv.created);
          }
          if (typeof conv.updated === "undefined" || conv.updated === null || conv.updated === "") {
            conv.updated = conv.created;
          } else {
            conv.updated = String(conv.updated);
          }
          if (typeof conv.queue_pending === "undefined") {
            conv.queue_pending = "0";
          }
          if (typeof conv.queue_running === "undefined") {
            conv.queue_running = "0";
          }
          if (typeof conv.queue_done === "undefined") {
            conv.queue_done = "0";
          }
          if (typeof conv.queue_last_status === "undefined") {
            conv.queue_last_status = "";
          }
          if (typeof conv.queue_first_id === "undefined") {
            conv.queue_first_id = "";
          }
          conv.decision_request = normalizeDecisionRequest(conv.decision_request);
          conv.approval_request = normalizeApprovalRequest(conv.approval_request);
        }
      }
      if (state.activeTriage && Number(state.triage.count || 0) < 1) {
        state.activeTriage = false;
      }
      saveWorkspaceStateCache(state.workspaces);
      bootstrapSeenConversationsIfNeeded();
      pruneSeenConversationState();
      pruneRunEventsByKnownConversations();
      applyRouteSelectionIfPending();
      ensureSelection();
      reconcileRunEventsFromQueueState();
      syncSelectionUrl(true);
    });
  }

  function loadModels() {
    return apiGet("models").then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load models");
      }
      state.modelLoadError = "";
      state.models = response.models || [];
    });
  }

  function loadModelCatalog() {
    return apiGet("model_catalog").then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load model catalog");
      }
      state.modelCatalog = response.available || [];
      state.modelInstalls = response.installs || [];
    });
  }

  function refreshModelData(options) {
    var opts = options || {};
    var force = !!opts.force;
    var silent = opts.silent !== false;
    var now = Date.now();
    if (modelAutoRefreshBusy && !force) {
      return Promise.resolve(false);
    }
    if (!force && modelAutoRefreshLastAt > 0 && now - modelAutoRefreshLastAt < 2500) {
      return Promise.resolve(false);
    }
    modelAutoRefreshBusy = true;
    return Promise.all([
      loadModels().catch(function (err) {
        state.models = [];
        state.modelLoadError = err && err.message ? err.message : "Model check failed";
        return null;
      }),
      loadModelCatalog().catch(function () {
        state.modelCatalog = [];
        state.modelInstalls = [];
        return null;
      })
    ]).then(function () {
      syncModelInstallPollingFromCatalog();
      modelAutoRefreshLastAt = Date.now();
      if (!silent) {
        renderUi();
      }
      return true;
    }).finally(function () {
      modelAutoRefreshBusy = false;
    });
  }

  function startModelAutoRefreshLoop() {
    if (modelAutoRefreshTimer) {
      clearInterval(modelAutoRefreshTimer);
      modelAutoRefreshTimer = null;
    }
    modelAutoRefreshTimer = setInterval(function () {
      refreshModelData({ silent: true }).then(function (updated) {
        if (updated) {
          renderUi();
        }
      }).catch(function () {
        return null;
      });
    }, 15000);
  }

  function stopModelAutoRefreshLoop() {
    if (modelAutoRefreshTimer) {
      clearInterval(modelAutoRefreshTimer);
      modelAutoRefreshTimer = null;
    }
  }

  function loadAppIcons() {
    return apiGet("app_icons").then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load app icons");
      }
      state.appIcons = {
        finder: String(response.finder || ""),
        textmate: String(response.textmate || "")
      };
    });
  }

  function stopModelInstallPolling() {
    if (modelInstallPollTimer) {
      clearInterval(modelInstallPollTimer);
      modelInstallPollTimer = null;
    }
  }

  function pollModelInstallStatus(jobId) {
    if (!jobId) {
      return Promise.resolve();
    }
    return apiGet("model_install_status", { job_id: jobId }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load install status");
      }
      state.modelInstallJob = response.job || null;
      state.modelInstallLog = response.job && response.job.log ? String(response.job.log) : "";
      if (response.job) {
        var replaced = false;
        for (var i = 0; i < state.modelInstalls.length; i += 1) {
          if (String(state.modelInstalls[i].id || "") === String(response.job.id || "")) {
            state.modelInstalls[i] = response.job;
            replaced = true;
            break;
          }
        }
        if (!replaced) {
          state.modelInstalls.unshift(response.job);
        }
      }

      var status = String((response.job && response.job.status) || "");
      if (status === "done" || status === "failed") {
        stopModelInstallPolling();
        return loadModels()
          .catch(function () { return null; })
          .then(function () {
            return loadModelCatalog().catch(function () { return null; });
          })
          .then(function () {
            renderUi();
          });
      }
      renderUi();
      return null;
    });
  }

  function ensureModelInstallPolling(jobId) {
    if (!jobId) {
      return;
    }
    stopModelInstallPolling();
    modelInstallPollTimer = setInterval(function () {
      pollModelInstallStatus(jobId).catch(function () {
        return null;
      });
    }, 1200);
  }

  function syncModelInstallPollingFromCatalog() {
    var runningJobId = "";
    for (var i = 0; i < state.modelInstalls.length; i += 1) {
      var job = state.modelInstalls[i] || {};
      if (String(job.status || "") === "running" && String(job.id || "")) {
        runningJobId = String(job.id);
        state.modelInstallJob = job;
        break;
      }
    }
    if (runningJobId) {
      ensureModelInstallPolling(runningJobId);
    } else {
      stopModelInstallPolling();
    }
  }

  function startModelInstall(modelName) {
    var target = trim(modelName);
    if (!target) {
      return Promise.resolve();
    }
    return apiPost("model_install_start", { model: target }, { timeoutMs: 12000 }).then(function (response) {
      if (!response.success || !response.job) {
        throw new Error(response.error || "Model install failed to start");
      }
      state.modelInstallJob = response.job;
      state.modelInstallLog = "";
      ensureModelInstallPolling(String(response.job.id || ""));
      renderUi();
      return pollModelInstallStatus(String(response.job.id || "")).catch(function () {
        return null;
      });
    });
  }

  function loadThemes() {
    return apiGet("themes").then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load themes");
      }
      state.themes = normalizeThemes(response.themes || []);
      ensureActiveThemeInList();
      applyTheme(state.activeTheme);
    }).catch(function () {
      state.themes = normalizeThemes(themeNameListFallback());
      ensureActiveThemeInList();
      applyTheme(state.activeTheme);
    });
  }

  function loadConversation(options) {
    var opts = options || {};
    var explicitWorkspaceId = "";
    var explicitConversationId = "";
    if (opts && Object.prototype.hasOwnProperty.call(opts, "workspaceId")) {
      explicitWorkspaceId = String(opts.workspaceId || "");
    }
    if (opts && Object.prototype.hasOwnProperty.call(opts, "conversationId")) {
      explicitConversationId = String(opts.conversationId || "");
    }
    var workspaceId = explicitWorkspaceId || state.activeWorkspaceId;
    var conversationId = explicitConversationId || state.activeConversationId;
    var isExplicitTarget = !!(explicitWorkspaceId || explicitConversationId);
    if (!workspaceId || !conversationId) {
      if (!isExplicitTarget) {
        state.activeConversation = null;
      }
      return Promise.resolve();
    }

    var requestOptions = null;
    if (opts && Number(opts.timeoutMs) > 0) {
      requestOptions = { timeoutMs: Number(opts.timeoutMs) };
    }

    return apiGet("get_conversation", {
      workspace_id: workspaceId,
      conversation_id: conversationId
    }, requestOptions).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load thread");
      }
      if (!isExplicitTarget && (state.activeWorkspaceId !== workspaceId || state.activeConversationId !== conversationId)) {
        return null;
      }
      var conversation = response.conversation || null;
      if (conversation) {
        conversation.decision_request = normalizeDecisionRequest(conversation.decision_request);
        conversation.approval_request = normalizeApprovalRequest(conversation.approval_request);
        if (Array.isArray(conversation.run_events)) {
          mergeConversationRunEvents(conversationId, conversation.run_events);
        }
        cacheConversationSnapshot(workspaceId, conversationId, conversation);
      }
      var isActiveTarget = state.activeWorkspaceId === workspaceId && state.activeConversationId === conversationId;
      if (isActiveTarget) {
        state.activeConversation = conversation;
        if (state.activeConversation) {
          finalizeStaleRunningEventsForConversation(workspaceId, state.activeConversation);
          reconcilePendingOutgoingFromConversation(workspaceId, conversationId, state.activeConversation);
          if (
            queueNumber(state.activeConversation.queue_pending) > 0 ||
            isQueueEditForConversation(workspaceId, conversationId)
          ) {
            loadQueueItems(workspaceId, conversationId, { minIntervalMs: 0 }).catch(function () {
              return null;
            });
          } else {
            clearQueueItemsForConversation(workspaceId, conversationId);
          }
        }
        if (opts.markSeen !== false) {
          markConversationSeen(workspaceId, conversationId, conversation);
        }
      }
      return conversation;
    });
  }

  function loadDraft(workspaceId) {
    if (!workspaceId) {
      return Promise.resolve("");
    }

    return apiGet("get_draft", { workspace_id: workspaceId }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load draft");
      }
      state.draftTextByWorkspace[workspaceId] = response.draft || "";
      return response.draft || "";
    });
  }

  function saveDraft(workspaceId, text) {
    if (!workspaceId) {
      return Promise.resolve();
    }

    return apiPost("save_draft", {
      workspace_id: workspaceId,
      draft: text
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to save draft");
      }
      state.draftTextByWorkspace[workspaceId] = text;
      var ws = getWorkspaceById(workspaceId);
      if (ws) {
        ws.draft_exists = trim(text) ? "1" : "0";
      }
    });
  }

  function saveDraftDebounced() {
    if (!state.activeDraftWorkspaceId) {
      return;
    }

    clearDraftAutosaveTimer();
    saveDraftTimer = setTimeout(function () {
      var workspaceId = state.activeDraftWorkspaceId;
      var draftText = el.runPrompt.value;
      saveDraft(workspaceId, draftText).catch(showError);
    }, 550);
  }

  function refreshGitStatus() {
    if (!state.activeWorkspaceId) {
      return Promise.resolve();
    }

    return apiGet("git_status", { workspace_id: state.activeWorkspaceId })
      .then(function (response) {
        if (!response.success) {
          throw new Error(response.error || "Failed to load git status");
        }
        state.gitByWorkspace[state.activeWorkspaceId] = {
          is_repo: !!response.is_repo,
          branch: response.branch || "",
          ahead: Number(response.ahead || 0),
          behind: Number(response.behind || 0),
          added: Number(response.added || 0),
          deleted: Number(response.deleted || 0),
          changes: Number(response.changes || 0),
          staged_changes: Number(response.staged_changes || 0),
          unstaged_changes: Number(response.unstaged_changes || 0)
        };
      })
      .catch(function (err) {
        state.gitByWorkspace[state.activeWorkspaceId] = {
          is_repo: false,
          branch: "",
          ahead: 0,
          behind: 0,
          added: 0,
          deleted: 0,
          changes: 0,
          staged_changes: 0,
          unstaged_changes: 0
        };
        throw err;
      });
  }

  function warmGitStatusForWorkspaces(workspaceIds) {
    var ids = Array.isArray(workspaceIds) ? workspaceIds.slice() : [];
    var chain = Promise.resolve();
    for (var i = 0; i < ids.length; i += 1) {
      (function (workspaceId) {
        if (!workspaceId || state.gitByWorkspace[workspaceId]) {
          return;
        }
        chain = chain.then(function () {
          return apiGet("git_status", { workspace_id: workspaceId })
            .then(function (response) {
              if (!response.success) {
                return;
              }
              state.gitByWorkspace[workspaceId] = {
                is_repo: !!response.is_repo,
                branch: response.branch || "",
                ahead: Number(response.ahead || 0),
                behind: Number(response.behind || 0),
                added: Number(response.added || 0),
                deleted: Number(response.deleted || 0),
                changes: Number(response.changes || 0),
                staged_changes: Number(response.staged_changes || 0),
                unstaged_changes: Number(response.unstaged_changes || 0)
              };
            })
            .catch(function () {
              return null;
            });
        });
      })(ids[i]);
    }
    return chain;
  }

  function refreshBranches() {
    if (!state.activeWorkspaceId) {
      return Promise.resolve();
    }

    return apiGet("git_branches", { workspace_id: state.activeWorkspaceId }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load branches");
      }
      state.branchesByWorkspace[state.activeWorkspaceId] = response.branches || [];
    });
  }

  function refreshDiff() {
    if (!state.activeWorkspaceId) {
      state.diffText = "";
      return Promise.resolve();
    }

    return apiGet("git_diff", { workspace_id: state.activeWorkspaceId }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load git diff");
      }
      state.diffText = response.diff || "";
      var gitState = activeGitState();
      if (!gitState.is_repo) {
        el.diffSummary.textContent = "Not a git repository.";
      } else {
        el.diffSummary.innerHTML = gitDeltaMarkup(response.added, response.deleted);
      }
    });
  }

  function refreshAll() {
    var modelsPromise = runWithRetry(loadModels, 3, 220).catch(function (err) {
      state.models = [];
      state.modelLoadError = err && err.message ? err.message : "Model check failed";
      return null;
    });
    var modelCatalogPromise = runWithRetry(loadModelCatalog, 2, 180).catch(function () {
      state.modelCatalog = [];
      state.modelInstalls = [];
      return null;
    });
    var appIconsPromise = runWithRetry(loadAppIcons, 2, 180).catch(function () {
      state.appIcons = { finder: "", textmate: "" };
      return null;
    });
    var themesPromise = runWithRetry(loadThemes, 2, 120).catch(function () {
      state.themes = normalizeThemes(themeNameListFallback());
      ensureActiveThemeInList();
      applyTheme(state.activeTheme);
      return null;
    });

    var sideDataPromise = Promise.all([
      modelsPromise,
      modelCatalogPromise,
      appIconsPromise,
      themesPromise
    ]).then(function () {
      syncModelInstallPollingFromCatalog();
      modelAutoRefreshLastAt = Date.now();
      renderUi();
    });

    return runWithRetry(loadState, 3, 220)
      .then(function () {
        renderUi();
      })
      .then(loadConversation)
      .then(function () {
        return syncCommandExecModeForWorkspace(state.activeWorkspaceId);
      })
      .then(function () {
        return refreshGitStatus().catch(function () {
          return null;
        });
      })
      .then(function () {
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (state.diffOpen) {
          return refreshDiff().catch(function () {
            return null;
          });
        }
        return null;
      })
      .then(function () {
        state.initialLoadComplete = true;
        renderUi();
        return sideDataPromise;
      });
  }

  function hydrateWorkspaceStateFromCache() {
    var cached = loadWorkspaceStateCache();
    if (!cached || !Array.isArray(cached.workspaces) || !cached.workspaces.length) {
      return false;
    }
    state.workspaces = cached.workspaces;
    for (var i = 0; i < state.workspaces.length; i += 1) {
      if (!Array.isArray(state.workspaces[i].conversations)) {
        state.workspaces[i].conversations = [];
      }
      for (var j = 0; j < state.workspaces[i].conversations.length; j += 1) {
        var conv = state.workspaces[i].conversations[j];
        if (typeof conv.created === "undefined" || conv.created === null || conv.created === "") {
          conv.created = typeof conv.updated !== "undefined" && conv.updated !== null && conv.updated !== "" ? String(conv.updated) : "0";
        } else {
          conv.created = String(conv.created);
        }
        if (typeof conv.updated === "undefined" || conv.updated === null || conv.updated === "") {
          conv.updated = conv.created;
        } else {
          conv.updated = String(conv.updated);
        }
        if (typeof conv.queue_pending === "undefined") {
          conv.queue_pending = "0";
        }
        if (typeof conv.queue_running === "undefined") {
          conv.queue_running = "0";
        }
        if (typeof conv.queue_done === "undefined") {
          conv.queue_done = "0";
        }
        if (typeof conv.queue_last_status === "undefined") {
          conv.queue_last_status = "";
        }
        if (typeof conv.queue_first_id === "undefined") {
          conv.queue_first_id = "";
        }
        conv.decision_request = normalizeDecisionRequest(conv.decision_request);
        conv.approval_request = normalizeApprovalRequest(conv.approval_request);
      }
    }
    bootstrapSeenConversationsIfNeeded();
    pruneSeenConversationState();
    pruneRunEventsByKnownConversations();
    applyRouteSelectionIfPending();
    ensureSelection();
    reconcileRunEventsFromQueueState();
    syncSelectionUrl(true);
    return true;
  }

  function addWorkspaceByPath(pathText, nameText) {
    var path = trim(pathText);
    var name = trim(nameText);
    if (!path) {
      return Promise.resolve();
    }

    return apiPost("add_workspace", {
      path: path,
      name: name,
      command_exec_mode: state.commandExecMode
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not add project");
      }

      return loadState().then(function () {
        if (response.workspace && response.workspace.id) {
          state.activeWorkspaceId = response.workspace.id;
          state.activeConversationId = "";
          state.activeConversation = null;
          state.activeDraftWorkspaceId = "";
          state.expandedWorkspaceIds[response.workspace.id] = true;
        }
        return refreshGitStatus().catch(function () {
          return null;
        });
      });
    });
  }

  function removeWorkspace(workspaceId) {
    var workspace = getWorkspaceById(workspaceId);
    if (!workspace) {
      return Promise.resolve();
    }

    return apiPost("delete_workspace", {
      workspace_id: workspaceId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not remove project");
      }
      if (state.activeWorkspaceId === workspaceId) {
        state.activeWorkspaceId = "";
        state.activeConversationId = "";
        state.activeConversation = null;
        state.activeDraftWorkspaceId = "";
      }
      if (state.openWorkspaceMenuWorkspaceId === workspaceId) {
        state.openWorkspaceMenuWorkspaceId = "";
      }
      var workspacePrefix = String(workspaceId || "") + "::";
      Object.keys(state.conversationCacheByKey).forEach(function (key) {
        if (String(key || "").indexOf(workspacePrefix) === 0) {
          delete state.conversationCacheByKey[key];
        }
      });
      delete state.expandedWorkspaceIds[workspaceId];
      delete state.gitByWorkspace[workspaceId];
      delete state.branchesByWorkspace[workspaceId];
      return refreshAll();
    });
  }

  function archiveConversation(workspaceId, conversationId) {
    if (!workspaceId || !conversationId) {
      return Promise.resolve();
    }

    return apiPost("archive_conversation", {
      workspace_id: workspaceId,
      conversation_id: conversationId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not archive thread");
      }

      if (state.activeWorkspaceId === workspaceId && state.activeConversationId === conversationId) {
        state.activeConversationId = "";
        state.activeConversation = null;
      }
      delete state.conversationCacheByKey[conversationReadKey(workspaceId, conversationId)];

      state.pendingArchiveKey = "";
      state.pendingArchiveReadyAt = 0;
      state.pendingArchiveSubmittingKey = "";
      return loadState()
        .then(function () {
          if (state.activeWorkspaceId) {
            return loadConversation().catch(function () {
              return null;
            });
          }
          return null;
        })
        .then(function () {
          renderUi();
        });
    });
  }

  function renameWorkspace(workspaceId, newName) {
    var name = trim(newName);
    if (!workspaceId) {
      return Promise.reject(new Error("Project is required."));
    }
    if (!name) {
      return Promise.reject(new Error("Project name is required."));
    }

    return apiPost("rename_workspace", {
      workspace_id: workspaceId,
      name: name
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not rename project");
      }

      var workspace = getWorkspaceById(workspaceId);
      if (workspace) {
        workspace.name = name;
      }
      if (state.openWorkspaceMenuWorkspaceId === workspaceId) {
        state.openWorkspaceMenuWorkspaceId = "";
      }
      renderUi();
    });
  }

  function addWorkspaceFromDropCandidate(pathText) {
    var candidate = trim(pathText);
    if (!candidate) {
      return Promise.reject(new Error("Dropped folder path unavailable here. Click + and use Browse."));
    }

    return addWorkspaceByPath(candidate, "").catch(function (firstErr) {
      var parent = dirname(candidate);
      if (parent && parent !== candidate) {
        return addWorkspaceByPath(parent, "");
      }
      throw firstErr;
    });
  }

  function selectWorkspace(workspaceId) {
    var selectionVersion = newSelectionVersion();
    state.chatAutoScroll = true;
    var workspace = getWorkspaceById(workspaceId);
    if (!workspace) {
      return Promise.resolve();
    }

    state.activeWorkspaceId = workspaceId;
    state.activeConversation = null;
    state.activeDraftWorkspaceId = "";
    state.openWorkspaceMenuWorkspaceId = "";
    state.expandedWorkspaceIds[workspaceId] = true;

    var conversations = getSortedConversations(workspace);
    if (conversations.length > 0) {
      state.activeConversationId = conversations[0].id;
      syncSelectionUrl(false);
      return loadConversation()
        .then(function () {
          if (!isSelectionVersionCurrent(selectionVersion)) {
            return;
          }
          el.runPrompt.value = "";
          resetComposerAttachments();
          return refreshGitStatus().catch(function () {
            return null;
          });
        })
        .then(function () {
          if (!isSelectionVersionCurrent(selectionVersion)) {
            return;
          }
          return refreshBranches().catch(function () {
            return null;
          });
        })
        .then(function () {
          if (!isSelectionVersionCurrent(selectionVersion)) {
            return;
          }
          if (state.diffOpen) {
            return refreshDiff().catch(function () {
              return null;
            });
          }
          return null;
        })
        .then(function () {
          if (!isSelectionVersionCurrent(selectionVersion)) {
            return;
          }
          return syncCommandExecModeForWorkspace(workspaceId);
        })
        .then(function () {
          if (!isSelectionVersionCurrent(selectionVersion)) {
            return;
          }
          renderUi();
        });
    }

    state.activeConversationId = "";
    syncSelectionUrl(false);
    if (workspace.draft_exists === "1") {
      return selectDraft(workspaceId);
    }

    el.runPrompt.value = "";
    resetComposerAttachments();

    return refreshGitStatus()
      .catch(function () {
        return null;
      })
      .then(function () {
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        return syncCommandExecModeForWorkspace(workspaceId);
      })
      .then(function () {
        renderUi();
      });
  }

  function selectConversation(workspaceId, conversationId) {
    var selectionVersion = newSelectionVersion();
    if (!isQueueEditForConversation(workspaceId, conversationId) && state.queueEdit.itemId) {
      clearQueueEditState();
    }
    state.chatAutoScroll = true;
    state.activeTriage = false;
    state.activeWorkspaceId = workspaceId;
    state.activeConversationId = conversationId;
    var workspace = getWorkspaceById(workspaceId);
    var summary = getConversationById(workspace, conversationId);
    var convKey = conversationReadKey(workspaceId, conversationId);
    var cachedConversation = cloneConversationData(state.conversationCacheByKey[convKey]);
    if (cachedConversation && summary) {
      var cachedUpdated = conversationUpdatedNumber(cachedConversation);
      var summaryUpdated = conversationUpdatedNumber(summary);
      if (summaryUpdated > 0 && cachedUpdated > 0 && summaryUpdated > cachedUpdated) {
        cachedConversation = null;
      }
    }
    if (!cachedConversation) {
      if (summary) {
        cachedConversation = {
          id: summary.id,
          title: summary.title || "Thread",
          model: summary.model || "",
          created: summary.created || "",
          updated: summary.updated || "",
          messages: [],
          decision_request: normalizeDecisionRequest(summary.decision_request),
          approval_request: normalizeApprovalRequest(summary.approval_request)
        };
      }
    }
    state.activeConversation = cachedConversation;
    state.activeDraftWorkspaceId = "";
    state.openWorkspaceMenuWorkspaceId = "";
    state.expandedWorkspaceIds[workspaceId] = true;
    syncSelectionUrl(false);
    renderUi();

    return loadConversation()
      .catch(function (firstErr) {
        return loadState()
          .then(function () {
            if (state.activeWorkspaceId !== workspaceId || state.activeConversationId !== conversationId) {
              return null;
            }
            return loadConversation();
          })
          .catch(function () {
            throw firstErr;
          });
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        el.runPrompt.value = "";
        resetComposerAttachments();
        return refreshGitStatus().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        if (state.diffOpen) {
          return refreshDiff().catch(function () {
            return null;
          });
        }
        return null;
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        return syncCommandExecModeForWorkspace(workspaceId);
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        renderUi();
      });
  }

  function selectDraft(workspaceId) {
    var selectionVersion = newSelectionVersion();
    if (state.queueEdit.itemId) {
      clearQueueEditState();
    }
    state.chatAutoScroll = true;
    state.activeTriage = false;
    state.activeWorkspaceId = workspaceId;
    state.activeConversationId = "";
    state.activeConversation = null;
    state.activeDraftWorkspaceId = workspaceId;
    state.openWorkspaceMenuWorkspaceId = "";
    state.expandedWorkspaceIds[workspaceId] = true;
    syncSelectionUrl(false);

    return loadDraft(workspaceId)
      .then(function (draft) {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        el.runPrompt.value = draft;
        resetComposerAttachments();
        return refreshGitStatus().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        return syncCommandExecModeForWorkspace(workspaceId);
      })
      .then(function () {
        if (!isSelectionVersionCurrent(selectionVersion)) {
          return;
        }
        renderUi();
      });
  }

  function createDraftForWorkspace(workspaceId) {
    state.chatAutoScroll = true;
    state.activeTriage = false;
    state.activeWorkspaceId = workspaceId;
    state.activeConversationId = "";
    state.activeConversation = null;
    state.activeDraftWorkspaceId = workspaceId;
    state.openWorkspaceMenuWorkspaceId = "";
    state.expandedWorkspaceIds[workspaceId] = true;

    return loadDraft(workspaceId)
      .then(function (draft) {
        el.runPrompt.value = draft;
        resetComposerAttachments();
        return syncCommandExecModeForWorkspace(workspaceId);
      })
      .then(function () {
        renderUi();
      })
      .then(function () {
        setTimeout(function () {
          el.runPrompt.focus();
        }, 0);
      });
  }

  function ensureConversationFromDraft(prompt) {
    if (!state.activeDraftWorkspaceId) {
      return Promise.resolve(state.activeConversationId);
    }

    var workspaceId = state.activeDraftWorkspaceId;
    var model = activeModelName();
    var title = titleFromPrompt(prompt);

    return apiPost("new_conversation", {
      workspace_id: workspaceId,
      title: title,
      model: model
    }).then(function (response) {
      if (!response.success || !response.conversation || !response.conversation.id) {
        throw new Error(response.error || "Failed to create thread from draft");
      }

      return saveDraft(workspaceId, "").catch(function () {
        return null;
      }).then(function () {
        state.activeDraftWorkspaceId = "";
        state.activeConversationId = response.conversation.id;
        state.activeConversation = null;

        return loadState().then(function () {
          state.activeWorkspaceId = workspaceId;
          state.activeConversationId = response.conversation.id;
          return loadConversation().then(function () {
            return response.conversation.id;
          });
        });
      });
    });
  }

  function applyModelSelection(modelName) {
    var model = trim(modelName);
    if (!model) {
      return Promise.resolve();
    }

    if (state.activeConversationId && state.activeWorkspaceId) {
      return apiPost("set_model", {
        workspace_id: state.activeWorkspaceId,
        conversation_id: state.activeConversationId,
        model: model
      }).then(function (response) {
        if (!response.success) {
          throw new Error(response.error || "Could not update model");
        }

        if (state.activeConversation) {
          state.activeConversation.model = model;
        }

        var ws = getWorkspaceById(state.activeWorkspaceId);
        var conv = getConversationById(ws, state.activeConversationId);
        if (conv) {
          conv.model = model;
        }
      });
    }

    if (state.activeDraftWorkspaceId) {
      state.draftModelByWorkspace[state.activeDraftWorkspaceId] = model;
    }

    return Promise.resolve();
  }

  function defaultCommandRulePattern(commandText) {
    var cmd = trim(commandText);
    if (!cmd) {
      return "^.+$";
    }
    var first = cmd.split(/\s+/)[0] || "";
    var escaped = first.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    if (!escaped) {
      return "^.+$";
    }
    return "^" + escaped + "([[:space:]].*)?$";
  }

  function openCommandApprovalPanel(commandText, reasonText) {
    return new Promise(function (resolve, reject) {
      if (
        !el.commandApprovalInline ||
        !el.commandApprovalInlineAllowOnce ||
        !el.commandApprovalInlineDenyOnce ||
        !el.commandApprovalInlineAllowRemember ||
        !el.commandApprovalInlineDenyRemember
      ) {
        openCommandApprovalModal(commandText, reasonText).then(resolve).catch(reject);
        return;
      }

      if (pendingCommandApproval && typeof pendingCommandApproval.cancel === "function") {
        pendingCommandApproval.cancel(new Error("Command approval replaced by a newer request."));
      }

      var done = false;
      function finish(value, isReject) {
        if (done) {
          return;
        }
        done = true;
        pendingCommandApproval = null;
        el.commandApprovalInline.classList.add("hidden");
        if (isReject) {
          reject(value instanceof Error ? value : new Error(String(value || "Command approval cancelled")));
        } else {
          resolve(value);
        }
      }

      function choice(decision, scope) {
        return function () {
          var matchMode = "exact";
          var pattern = String(commandText || "");
          if (scope === "remember") {
            matchMode = trim(el.commandApprovalInlineMatchMode && el.commandApprovalInlineMatchMode.value) || "exact";
            pattern = trim(el.commandApprovalInlinePattern && el.commandApprovalInlinePattern.value) || String(commandText || "");
          }
          finish({
            decision: decision,
            scope: scope,
            match_mode: matchMode,
            pattern: pattern
          }, false);
        };
      }

      function closeHandler() {
        finish(new Error("Command approval cancelled"), true);
      }

      pendingCommandApproval = {
        cancel: closeHandler
      };

      var reason = trim(reasonText);
      if (el.commandApprovalInlineText) {
        el.commandApprovalInlineText.textContent = reason
          ? "Agent requested a command (" + reason + ")."
          : "Agent requested a command.";
      }
      if (el.commandApprovalInlineCommand) {
        el.commandApprovalInlineCommand.textContent = String(commandText || "");
      }
      if (el.commandApprovalInlineMatchMode) {
        el.commandApprovalInlineMatchMode.value = "exact";
      }
      if (el.commandApprovalInlinePattern) {
        el.commandApprovalInlinePattern.value = defaultCommandRulePattern(commandText);
      }

      el.commandApprovalInlineAllowOnce.onclick = choice("allow", "once");
      el.commandApprovalInlineDenyOnce.onclick = choice("deny", "once");
      el.commandApprovalInlineAllowRemember.onclick = choice("allow", "remember");
      el.commandApprovalInlineDenyRemember.onclick = choice("deny", "remember");
      if (el.commandApprovalInlineClose) {
        el.commandApprovalInlineClose.onclick = closeHandler;
      }

      el.commandApprovalInline.classList.remove("hidden");
      renderUi();
      window.setTimeout(function () {
        if (el.commandApprovalInlineAllowOnce) {
          el.commandApprovalInlineAllowOnce.focus();
        }
      }, 0);
    });
  }

  function openCommandApprovalModal(commandText, reasonText) {
    return new Promise(function (resolve, reject) {
      if (!el.commandApprovalModal) {
        reject(new Error("Command approval UI is unavailable."));
        return;
      }

      if (el.commandApprovalText) {
        var reason = trim(reasonText);
        el.commandApprovalText.textContent = reason
          ? "Agent requested a command (" + reason + ")."
          : "Agent requested a command.";
      }
      if (el.commandApprovalCommand) {
        el.commandApprovalCommand.textContent = String(commandText || "");
      }
      if (el.commandApprovalMatchMode) {
        el.commandApprovalMatchMode.value = "exact";
      }
      if (el.commandApprovalPattern) {
        el.commandApprovalPattern.value = defaultCommandRulePattern(commandText);
      }

      var done = false;
      function finish(value, isReject) {
        if (done) {
          return;
        }
        done = true;
        closeModal(el.commandApprovalModal);
        if (isReject) {
          reject(value instanceof Error ? value : new Error(String(value || "Command approval cancelled")));
        } else {
          resolve(value);
        }
      }

      function choice(decision, scope) {
        return function () {
          var matchMode = "exact";
          var pattern = String(commandText || "");
          if (scope === "remember") {
            matchMode = trim(el.commandApprovalMatchMode && el.commandApprovalMatchMode.value) || "exact";
            pattern = trim(el.commandApprovalPattern && el.commandApprovalPattern.value) || String(commandText || "");
          }
          finish({
            decision: decision,
            scope: scope,
            match_mode: matchMode,
            pattern: pattern
          }, false);
        };
      }

      function closeHandler() {
        finish(new Error("Command approval cancelled"), true);
      }

      var handlers = [
        [el.commandApprovalAllowOnce, choice("allow", "once")],
        [el.commandApprovalDenyOnce, choice("deny", "once")],
        [el.commandApprovalAllowRemember, choice("allow", "remember")],
        [el.commandApprovalDenyRemember, choice("deny", "remember")],
        [el.commandApprovalClose, closeHandler]
      ];

      function bindAll() {
        for (var i = 0; i < handlers.length; i += 1) {
          var pair = handlers[i];
          if (pair[0]) {
            pair[0].addEventListener("click", pair[1], { once: true });
          }
        }
        if (el.commandApprovalModal) {
          el.commandApprovalModal.addEventListener("click", overlayClick, { once: true });
        }
      }

      function overlayClick(event) {
        if (event.target === el.commandApprovalModal) {
          closeHandler();
          return;
        }
        if (el.commandApprovalModal) {
          el.commandApprovalModal.addEventListener("click", overlayClick, { once: true });
        }
      }

      bindAll();
      openModal(el.commandApprovalModal);
      window.setTimeout(function () {
        if (el.commandApprovalAllowOnce) {
          el.commandApprovalAllowOnce.focus();
        }
      }, 0);
    });
  }

  function handleBlockedCommandsApproval(workspaceId, conversationId, blockedCommands) {
    var list = Array.isArray(blockedCommands) ? blockedCommands.slice(0) : [];
    if (!list.length) {
      return Promise.resolve(false);
    }
    setAwaitingApprovalState(workspaceId, conversationId, true);
    renderUi();

    function step(index) {
      if (index >= list.length) {
        return Promise.resolve(true);
      }
      var item = list[index] || {};
      var commandText = String(item.command || "");
      var reasonText = String(item.reason || "");
      if (!trim(commandText)) {
        return step(index + 1);
      }
      return openCommandApprovalPanel(commandText, reasonText).then(function (choice) {
        return apiPost("command_approval_save", {
          workspace_id: workspaceId,
          command: commandText,
          decision: choice.decision || "deny",
          scope: choice.scope || "once",
          match_mode: choice.match_mode || "exact",
          pattern: choice.pattern || commandText
        }).then(function (response) {
          if (!response || !response.success) {
            throw new Error((response && response.error) || "Could not save command approval.");
          }
          if ((choice.decision || "") === "deny") {
            return false;
          }
          return step(index + 1);
        });
      });
    }

    return step(0).finally(function () {
      setAwaitingApprovalState(workspaceId, conversationId, false);
      renderUi();
    });
  }

  function runAgent(workspaceId, conversationId, promptText, options) {
    var runOptions = options || {};
    var preserveSelection = runOptions.preserveSelection !== false;
    var approvalRetry = runOptions.approvalRetry === true;
    var queueItemId = String(runOptions.queueItemId || "");
    var explicitModeOverride = trim(String(runOptions.runMode || ""));
    var explicitAssistantModeOverride = trim(String(runOptions.assistantModeId || ""));
    var explicitComputeBudgetOverride = trim(String(runOptions.computeBudget || ""));
    var explicitPermissionModeOverride = normalizePermissionModeValue(runOptions.permissionMode || "");
    var explicitCommandExecModeOverride = normalizeCommandExecModeValue(runOptions.commandExecMode || "");
    var explicitSkillIdsOverride = Array.isArray(runOptions.explicitSkillIds) ? runOptions.explicitSkillIds : [];
    if (explicitModeOverride) {
      explicitModeOverride = normalizeRunMode(explicitModeOverride);
    }
    if (explicitAssistantModeOverride) {
      explicitAssistantModeOverride = normalizeAssistantModeId(explicitAssistantModeOverride);
    }
    if (explicitComputeBudgetOverride) {
      explicitComputeBudgetOverride = normalizeComputeBudget(explicitComputeBudgetOverride);
    }
    var directive = parsePromptModeDirective(promptText);
    var promptForRun = trim(directive.prompt || promptText);
    var modeOverride = explicitModeOverride || (directive.mode ? normalizeRunMode(directive.mode) : "");
    var directiveSkillIds = Array.isArray(directive.skillIds) ? directive.skillIds : [];
    var explicitSkillIdsForRun = mergeSkillIdLists(explicitSkillIdsOverride, directiveSkillIds);
    var attachmentList = Array.isArray(runOptions.attachments) ? runOptions.attachments : [];
    var attachmentIds = [];
    var attachmentNames = [];

    if (!workspaceId || !conversationId) {
      return Promise.reject(new Error("Choose a project thread first."));
    }
    if (!promptForRun) {
      return Promise.reject(new Error("Prompt is empty."));
    }

    for (var i = 0; i < attachmentList.length; i += 1) {
      var item = attachmentList[i] || {};
      if (item.id) {
        attachmentIds.push(String(item.id));
      }
      if (item.name) {
        attachmentNames.push(String(item.name));
      }
    }

    var pendingEvent = runOptions.pendingEvent || null;
    var preferredEventId = "";
    if (queueItemId && /^[A-Za-z0-9._-]+$/.test(queueItemId)) {
      preferredEventId = "run-" + queueItemId;
    }
    if (!pendingEvent) {
      pendingEvent = pushRunEvent(conversationId, {
        id: preferredEventId,
        status: "running",
        started_at: new Date().toISOString(),
        stream_text: ""
      });
    } else if (preferredEventId && String(pendingEvent.id || "") !== preferredEventId) {
      pendingEvent.id = preferredEventId;
      persistRunEventsSoon();
    }

    if (
      !approvalRetry &&
      !queueItemId &&
      state.activeWorkspaceId === workspaceId &&
      state.activeConversation &&
      state.activeConversation.id === conversationId
    ) {
      consumePendingOutgoingByText(outgoingKeyFor(workspaceId, conversationId, ""), promptText);
      if (!Array.isArray(state.activeConversation.messages)) {
        state.activeConversation.messages = [];
      }
      var userContent = promptForRun;
      if (attachmentNames.length) {
        userContent += "\n\nAttached files:\n- " + attachmentNames.join("\n- ");
      }
      state.activeConversation.messages.push({ role: "user", content: userContent });
      cacheActiveConversationSnapshot(workspaceId, conversationId);
    }

    renderUi();

    var runProfile = modeOverride ? effectiveRunProfileForMode(modeOverride) : effectiveRunProfile();
    var assistantModeForRun = "";
    if (normalizeRunMode(runProfile.mode) === "assistant") {
      assistantModeForRun = explicitAssistantModeOverride || normalizeAssistantModeId(state.assistantModeId);
    }
    var computeBudgetForRun = explicitComputeBudgetOverride || normalizeComputeBudget(runProfile.computeBudget || state.computeBudget);
    var permissionModeForRun = explicitPermissionModeOverride || normalizePermissionModeValue(state.permissionMode) || "default";
    var commandExecModeForRun = explicitCommandExecModeOverride || normalizeCommandExecModeValue(state.commandExecMode) || "ask-some";
    var selectedIterations = Number(runProfile.maxIterations || 2);
    if (computeBudgetForRun === "long" && selectedIterations < 10) {
      selectedIterations += 2;
    } else if (computeBudgetForRun === "until-complete" && selectedIterations < 12) {
      selectedIterations += 4;
    }
    var streamSession = String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000));
    var streamOffset = 0;
    var streamPollActive = true;
    var streamPollBusy = false;
    var streamRenderTimer = null;
    var streamTimerKey = workspaceId + "::" + conversationId;

    if (runStreamPollTimers[streamTimerKey]) {
      clearInterval(runStreamPollTimers[streamTimerKey]);
      delete runStreamPollTimers[streamTimerKey];
    }

    function stopStreamPoll() {
      streamPollActive = false;
      if (streamRenderTimer) {
        clearTimeout(streamRenderTimer);
        streamRenderTimer = null;
      }
      if (runStreamPollTimers[streamTimerKey]) {
        clearInterval(runStreamPollTimers[streamTimerKey]);
        delete runStreamPollTimers[streamTimerKey];
      }
    }

    function scheduleStreamRender() {
      if (streamRenderTimer) {
        return;
      }
      streamRenderTimer = setTimeout(function () {
        streamRenderTimer = null;
        renderUi();
      }, 260);
    }

    function pollStreamOnce() {
      if (!streamPollActive || streamPollBusy) {
        return;
      }
      streamPollBusy = true;
      apiGet("run_stream_poll", {
        workspace_id: workspaceId,
        conversation_id: conversationId,
        stream_session: streamSession,
        offset: String(streamOffset)
      }, { timeoutMs: 1200 })
        .then(function (response) {
          if (!response || !response.success) {
            return;
          }
          var delta = String(response.delta || "");
          var taskStatus = normalizeRunTaskStatusSnapshot(response.task_status);
          streamOffset = Number(response.offset || streamOffset || 0);
          if (delta && pendingEvent) {
            pendingEvent.stream_text = String(pendingEvent.stream_text || "") + delta;
            persistRunEventsSoon();
            scheduleStreamRender();
          }
          if (taskStatus && pendingEvent) {
            pendingEvent.task_status = taskStatus;
            persistRunEventsSoon();
            scheduleStreamRender();
          }
        })
        .catch(function () {
          return null;
        })
        .finally(function () {
          streamPollBusy = false;
        });
    }

    runStreamPollTimers[streamTimerKey] = setInterval(pollStreamOnce, 700);
    pollStreamOnce();

    return apiPost("run", {
      workspace_id: workspaceId,
      conversation_id: conversationId,
      prompt: promptForRun,
      permission_mode: permissionModeForRun,
      command_exec_mode: commandExecModeForRun,
      approval_retry: approvalRetry ? "1" : "0",
      network_access: state.networkAccess ? "1" : "0",
      web_access: state.webAccess ? "1" : "0",
      attachment_ids: attachmentIds.join(","),
      queue_item_id: queueItemId,
      advanced_loop: runProfile.advancedLoop ? "1" : "0",
      run_mode: runProfile.mode,
      assistant_mode_id: assistantModeForRun,
      compute_budget: computeBudgetForRun,
      explicit_skill_ids: explicitSkillIdsForRun.join(","),
      reasoning_effort: runProfile.reasoning,
      max_iterations: String(selectedIterations),
      stream_session: streamSession
    })
      .then(function (response) {
        stopStreamPoll();
        if (!response.success) {
          throw new Error(response.error || "Run failed");
        }
        var decisionRequest = normalizeDecisionRequest(response.decision_request);
        if (typeof response.decision_request !== "undefined") {
          setConversationDecisionRequest(workspaceId, conversationId, decisionRequest);
        }
        if (
          state.activeConversation &&
          state.activeWorkspaceId === workspaceId &&
          state.activeConversationId === conversationId
        ) {
          state.activeConversation.decision_request = decisionRequest;
        }
        var assistantText = trim(String(response.assistant || ""));
        var responseQueueStatus = String(response.queue_last_status || "");
        var responseApprovalRequest = normalizeApprovalRequest(response.approval_request);
        var awaitingApproval = responseQueueStatus === "awaiting_approval" || !!responseApprovalRequest;
        var awaitingDecision = responseQueueStatus === "awaiting_decision" || !!decisionRequest;
        if (responseQueueStatus) {
          setConversationQueueFields(workspaceId, conversationId, {
            lastStatus: responseQueueStatus,
            approvalRequest: typeof response.approval_request === "undefined" ? undefined : responseApprovalRequest
          });
        }
        setAwaitingApprovalState(workspaceId, conversationId, awaitingApproval);
        if (
          state.activeConversation &&
          state.activeWorkspaceId === workspaceId &&
          state.activeConversationId === conversationId &&
          typeof response.approval_request !== "undefined"
        ) {
          state.activeConversation.approval_request = responseApprovalRequest;
        }
        if (assistantLooksLikeTrace(assistantText)) {
          if (pendingEvent && !trim(String(pendingEvent.failures || ""))) {
            pendingEvent.failures = assistantText;
          }
          assistantText = "";
        }
        if (!assistantText) {
          var attemptCount = runTraceAttemptCount(response || {});
          if (!attemptCount && pendingEvent) {
            attemptCount = runTraceAttemptCount(pendingEvent);
          }
          assistantText = attemptCount > 0
            ? "I couldn't complete that run after " + attemptCount + " attempt" + (attemptCount === 1 ? "" : "s") + ". Check the Thinking trace and try again."
            : "I couldn't produce a final response for that run. Please retry.";
        }

        appendAssistantMessageOptimistic(workspaceId, conversationId, assistantText);

        var blockedCommands = Array.isArray(response.blocked_commands) ? response.blocked_commands : [];
        if (blockedCommands.length && !queueItemId) {
          return handleBlockedCommandsApproval(workspaceId, conversationId, blockedCommands).then(function (approved) {
            if (!approved) {
              throw new Error("Command execution denied.");
            }
            return runAgent(workspaceId, conversationId, promptText, {
              preserveSelection: preserveSelection,
              attachments: attachmentList,
              queueItemId: queueItemId,
              runMode: modeOverride,
              assistantModeId: assistantModeForRun,
              computeBudget: computeBudgetForRun,
              explicitSkillIds: explicitSkillIdsForRun,
              approvalRetry: true,
              pendingEvent: pendingEvent
            });
          });
        }

        if (pendingEvent) {
          pendingEvent.status = awaitingApproval
            ? "awaiting_approval"
            : (awaitingDecision ? "awaiting_decision" : "done");
          pendingEvent.model = response.model || "";
          pendingEvent.plan = response.plan || "";
          pendingEvent.commands = response.commands || [];
          pendingEvent.git_status = response.git_status || "";
          pendingEvent.git_diff = response.git_diff || "";
          pendingEvent.state = response.state || "";
          pendingEvent.failures = response.failures || "";
          pendingEvent.session_log = response.session_log || "";
          pendingEvent.task_status = normalizeRunTaskStatusSnapshot(response.task_status);
          pendingEvent.finished_at = new Date().toISOString();
          pendingEvent.decision_hint = trim(String(response.decision_hint || ""));
          persistRunEventsSoon();
        }
        renderUi();

        return loadState()
          .then(function () {
            if (!preserveSelection) {
              state.activeWorkspaceId = workspaceId;
              state.activeConversationId = conversationId;
              state.activeDraftWorkspaceId = "";
            }
            return loadConversation({
              workspaceId: workspaceId,
              conversationId: conversationId,
              timeoutMs: 9000,
              markSeen: false
            }).catch(function () {
              if (
                assistantText &&
                state.activeConversation &&
                state.activeWorkspaceId === workspaceId &&
                state.activeConversation.id === conversationId
              ) {
                if (!Array.isArray(state.activeConversation.messages)) {
                  state.activeConversation.messages = [];
                }
                var msgs = state.activeConversation.messages;
                var last = msgs.length ? msgs[msgs.length - 1] : null;
                if (!last || last.role !== "assistant" || String(last.content || "") !== assistantText) {
                  msgs.push({ role: "assistant", content: assistantText });
                  cacheActiveConversationSnapshot(workspaceId, conversationId);
                }
              }
              return null;
            });
          })
          .then(function () {
            return refreshGitStatus().catch(function () {
              return null;
            });
          })
          .then(function () {
            return refreshBranches().catch(function () {
              return null;
            });
          })
          .then(function () {
            if (state.diffOpen) {
              return refreshDiff().catch(function () {
                return null;
              });
            }
            return null;
          })
          .then(function () {
            renderUi();
            return {
              awaitingDecision: awaitingDecision,
              awaitingApproval: awaitingApproval
            };
          });
      })
      .catch(function (err) {
        stopStreamPoll();
        setAwaitingApprovalState(workspaceId, conversationId, false);
        if (pendingEvent) {
          pendingEvent.status = "error";
          pendingEvent.error = err && err.message ? err.message : String(err);
          pendingEvent.finished_at = new Date().toISOString();
          persistRunEventsSoon();
        }
        renderUi();
        throw err;
      })
      .finally(function () {
        stopStreamPoll();
      });
  }

  function applyQueueStateFromResponse(workspaceId, conversationId, response) {
    if (!response) {
      return;
    }

    var pendingCount = queueNumber(response.queue_pending);

    setConversationQueueFields(workspaceId, conversationId, {
      pending: pendingCount,
      running: Number(response.queue_running || 0) > 0,
      done: Number(response.queue_done || 0) > 0,
      lastStatus: response.queue_last_status || "",
      firstId: response.queue_first_id || "",
      decisionRequest: typeof response.decision_request === "undefined" ? undefined : response.decision_request,
      approvalRequest: typeof response.approval_request === "undefined" ? undefined : response.approval_request
    });

    var queueLastStatus = String(response.queue_last_status || "");
    var responseRunning = Number(response.queue_running || 0) > 0;
    updateAwaitingApprovalFromQueueSnapshot(workspaceId, conversationId, {
      lastStatus: queueLastStatus,
      approvalRequest: response.approval_request,
      pending: pendingCount,
      running: responseRunning
    });
    releaseApprovalAnswerUiPendingIfAdvanced(workspaceId, conversationId, {
      queue_last_status: queueLastStatus,
      approval_request: response.approval_request
    });
    var queueTerminal = !responseRunning && pendingCount === 0;
    if (queueTerminal) {
      var eventStatus = queueLastStatus;
      if (
        eventStatus !== "done" &&
        eventStatus !== "error" &&
        eventStatus !== "cancelled" &&
        eventStatus !== "awaiting_decision" &&
        eventStatus !== "awaiting_approval"
      ) {
        eventStatus = "done";
      }
      finalizeAllRunningEvents(
        conversationId,
        eventStatus || "done",
        eventStatus === "error" ? "Run did not complete." : ""
      );
      if (eventStatus !== "awaiting_approval") {
        setAwaitingApprovalState(workspaceId, conversationId, false);
      }
    }
    if (
      !responseRunning &&
      state.busy &&
      String(state.runningWorkspaceId || "") === String(workspaceId || "") &&
      String(state.runningConversationId || "") === String(conversationId || "")
    ) {
      var eventStatus = queueLastStatus;
      if (
        eventStatus !== "done" &&
        eventStatus !== "error" &&
        eventStatus !== "cancelled" &&
        eventStatus !== "awaiting_decision" &&
        eventStatus !== "awaiting_approval"
      ) {
        eventStatus = "done";
      }
      finalizeAllRunningEvents(
        conversationId,
        eventStatus || "done",
        eventStatus === "error" ? "Run did not complete." : ""
      );
      setBusy(false);
    }

    if (pendingCount === 0 && conversationId) {
      delete state.lastQueuedItemIdByConversation[conversationId];
      clearQueueItemsForConversation(workspaceId, conversationId);
      if (isQueueEditForConversation(workspaceId, conversationId)) {
        clearQueueEditState();
      }
    }

    var workspace = getWorkspaceById(workspaceId);
    var conversation = getConversationById(workspace, conversationId);
    if (conversation) {
      finalizeStaleRunningEventsForConversation(workspaceId, conversation);
    }
  }

  function enqueuePrompt(workspaceId, conversationId, promptText, position, attachmentIds, runMode, assistantModeId, computeBudget, explicitSkillIds, permissionMode, commandExecMode) {
    var attachmentList = Array.isArray(attachmentIds) ? attachmentIds : [];
    var normalizedMode = normalizeRunMode(runMode || state.runMode);
    var normalizedAssistantMode = normalizedMode === "assistant" ? normalizeAssistantModeId(assistantModeId || state.assistantModeId) : "";
    var normalizedComputeBudget = normalizeComputeBudget(computeBudget || state.computeBudget);
    var normalizedPermissionMode = normalizePermissionModeValue(permissionMode || state.permissionMode) || "default";
    var normalizedCommandExecMode = normalizeCommandExecModeValue(commandExecMode || state.commandExecMode) || "ask-some";
    var normalizedSkillIds = mergeSkillIdLists(explicitSkillIds, []);
    return apiPost("queue_enqueue", {
      workspace_id: workspaceId,
      conversation_id: conversationId,
      prompt: promptText,
      position: position || "tail",
      attachments: attachmentList.join(","),
      run_mode: normalizedMode,
      assistant_mode_id: normalizedAssistantMode,
      compute_budget: normalizedComputeBudget,
      permission_mode: normalizedPermissionMode,
      command_exec_mode: normalizedCommandExecMode,
      explicit_skill_ids: normalizedSkillIds.join(",")
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not queue message");
      }
      applyQueueStateFromResponse(workspaceId, conversationId, response);
      if (response.item_id) {
        state.lastQueuedItemIdByConversation[conversationId] = String(response.item_id);
      }
      return loadQueueItems(workspaceId, conversationId, { force: true, minIntervalMs: 0 }).catch(function () {
        return null;
      }).then(function () {
        return response;
      });
    });
  }

  function queueFinish(workspaceId, conversationId, itemId, status, errorText) {
    return apiPost("queue_finish", {
      workspace_id: workspaceId,
      conversation_id: conversationId,
      item_id: itemId || "",
      status: status || "done",
      error: errorText || ""
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not finalize queue item");
      }
      applyQueueStateFromResponse(workspaceId, conversationId, response);
      return loadQueueItems(workspaceId, conversationId, { force: true, minIntervalMs: 0 }).catch(function () {
        return null;
      }).then(function () {
        return response;
      });
    });
  }

  function findConversationStateEntry(stateResponse, workspaceId, conversationId) {
    if (!stateResponse || !stateResponse.success || !Array.isArray(stateResponse.workspaces)) {
      return null;
    }
    for (var i = 0; i < stateResponse.workspaces.length; i += 1) {
      var workspace = stateResponse.workspaces[i];
      if (!workspace || String(workspace.id || "") !== String(workspaceId || "")) {
        continue;
      }
      var conversations = Array.isArray(workspace.conversations) ? workspace.conversations : [];
      for (var j = 0; j < conversations.length; j += 1) {
        var conversation = conversations[j];
        if (conversation && String(conversation.id || "") === String(conversationId || "")) {
          return conversation;
        }
      }
    }
    return null;
  }

  function startQueueCompletionWatch(workspaceId, conversationId, queueItemId, computeBudget) {
    var active = true;
    var inFlight = false;
    var pollTimer = null;
    var maxWaitMs = computeBudgetQueueWatchTimeoutMs(computeBudget || state.computeBudget);
    var pollFailures = 0;
    var missingConversationPolls = 0;

    var promise = new Promise(function (resolve) {
      function finish(payload) {
        if (!active) {
          return;
        }
        active = false;
        if (pollTimer) {
          clearInterval(pollTimer);
          pollTimer = null;
        }
        resolve(payload || null);
      }

      function checkOnce() {
        if (!active || inFlight) {
          return;
        }
        inFlight = true;
        apiGet("state", {}, { timeoutMs: 12000 })
          .then(function (response) {
            if (!active) {
              return;
            }
            var hasQueuedOrRunning = hasAnyQueuedOrRunningConversationInStateResponse(response);
            var conversation = findConversationStateEntry(response, workspaceId, conversationId);
            if (!conversation) {
              missingConversationPolls += 1;
              if (!hasQueuedOrRunning || missingConversationPolls >= 4) {
                finish({
                  lastStatus: "done",
                  pending: 0,
                  firstId: "",
                  decisionRequest: undefined,
                  approvalRequest: undefined
                });
              }
              return;
            }
            missingConversationPolls = 0;
            var running = String(conversation.queue_running || "0") === "1";
            var pending = queueNumber(conversation.queue_pending);
            var firstId = String(conversation.queue_first_id || "");
            var lastStatus = String(conversation.queue_last_status || "");
            pollFailures = 0;

            if (running) {
              return;
            }
            if (
              lastStatus !== "done" &&
              lastStatus !== "error" &&
              lastStatus !== "cancelled" &&
              lastStatus !== "awaiting_approval" &&
              lastStatus !== "awaiting_decision"
            ) {
              return;
            }
            if (pending > 0 && queueItemId && firstId === String(queueItemId || "")) {
              return;
            }

            finish({
              lastStatus: lastStatus,
              pending: pending,
              firstId: firstId,
              decisionRequest: typeof conversation.decision_request === "undefined" ? undefined : conversation.decision_request,
              approvalRequest: typeof conversation.approval_request === "undefined" ? undefined : conversation.approval_request
            });
          })
          .catch(function () {
            pollFailures += 1;
            if (pollFailures >= 5) {
              finish({
                lastStatus: "error",
                pending: 0,
                firstId: "",
                decisionRequest: undefined
              });
            }
            return null;
          })
          .finally(function () {
            inFlight = false;
          });
      }

      pollTimer = setInterval(checkOnce, 2400);
      setTimeout(checkOnce, 900);
      setTimeout(function () {
        finish({
          lastStatus: "error",
          pending: 0,
          firstId: "",
          decisionRequest: undefined
        });
      }, maxWaitMs);
    });

    return {
      promise: promise,
      stop: function () {
        active = false;
        if (pollTimer) {
          clearInterval(pollTimer);
          pollTimer = null;
        }
      }
    };
  }

  function executeQueuedItem(workspaceId, conversationId, queueItem, executeOptions) {
    var item = queueItem || {};
    var options = executeOptions || {};
    var itemId = item.id || "";
    var runError = null;
    var runResult = null;
    var finalStatus = "done";
    var finalErrorText = "";
    var queueFinalizeApplied = false;
    var queueWatch = null;
    var resumedPendingEvent = null;

    if (itemId && state.lastQueuedItemIdByConversation[conversationId] === itemId) {
      delete state.lastQueuedItemIdByConversation[conversationId];
    }
    if (trim(String(item.prompt || ""))) {
      consumePendingOutgoingByText(outgoingKeyFor(workspaceId, conversationId, ""), String(item.prompt || ""));
    }

    setBusy(true, workspaceId, conversationId);
    setConversationQueueFields(workspaceId, conversationId, {
      running: true,
      done: false,
      lastStatus: "running"
    });
    if (options.approvalRetry === true) {
      resumedPendingEvent = findLatestRunEventByStatus(conversationId, ["awaiting_approval", "done", "running"]);
      if (resumedPendingEvent) {
        resumedPendingEvent.status = "running";
        resumedPendingEvent.finished_at = "";
        resumedPendingEvent.error = "";
        if (!trim(String(resumedPendingEvent.started_at || ""))) {
          resumedPendingEvent.started_at = new Date().toISOString();
        }
        persistRunEventsSoon();
      }
    }
    renderUi();

    queueWatch = startQueueCompletionWatch(workspaceId, conversationId, itemId, item.compute_budget || state.computeBudget);

    function applyWatchInfo(watchInfo) {
      if (!watchInfo) {
        return false;
      }
      finalStatus = String(watchInfo.lastStatus || "done");
      if (
        finalStatus !== "done" &&
        finalStatus !== "error" &&
        finalStatus !== "cancelled" &&
        finalStatus !== "awaiting_decision" &&
        finalStatus !== "awaiting_approval"
      ) {
        finalStatus = "done";
      }
      queueFinalizeApplied = true;
      if (typeof watchInfo.decisionRequest !== "undefined") {
        setConversationQueueFields(workspaceId, conversationId, {
          decisionRequest: watchInfo.decisionRequest
        });
      }
      if (typeof watchInfo.approvalRequest !== "undefined") {
        setConversationQueueFields(workspaceId, conversationId, {
          approvalRequest: watchInfo.approvalRequest
        });
      }
      setAwaitingApprovalState(workspaceId, conversationId, finalStatus === "awaiting_approval");
      setConversationQueueFields(workspaceId, conversationId, {
        pending: queueNumber(watchInfo.pending),
        running: false,
        done: finalStatus === "done",
        lastStatus: finalStatus,
        firstId: watchInfo.firstId || ""
      });
      if (finalStatus === "error") {
        runError = new Error("Run ended with an error.");
        finalErrorText = runError.message;
      } else {
        finalErrorText = "";
        runResult = {
          awaitingDecision: finalStatus === "awaiting_decision",
          awaitingApproval: finalStatus === "awaiting_approval"
        };
      }
      finalizeAllRunningEvents(
        conversationId,
        finalStatus,
        finalStatus === "error" ? finalErrorText || "Run did not complete." : finalErrorText
      );
      if (
        state.busy &&
        String(state.runningWorkspaceId || "") === String(workspaceId || "") &&
        String(state.runningConversationId || "") === String(conversationId || "")
      ) {
        setBusy(false);
      }
      renderUi();
      return true;
    }

    return Promise.race([
      runAgent(workspaceId, conversationId, item.prompt || "", {
        preserveSelection: true,
        attachments: Array.isArray(item.attachments) ? item.attachments : [],
        queueItemId: itemId,
        runMode: normalizeRunMode(item.run_mode || "auto"),
        assistantModeId: item.assistant_mode_id || "",
        computeBudget: normalizeComputeBudget(item.compute_budget || "auto"),
        permissionMode: normalizePermissionModeValue(item.permission_mode || ""),
        commandExecMode: normalizeCommandExecModeValue(item.command_exec_mode || ""),
        explicitSkillIds: Array.isArray(item.explicit_skill_ids) ? item.explicit_skill_ids : [],
        approvalRetry: options.approvalRetry === true,
        pendingEvent: resumedPendingEvent
      })
        .then(function (result) {
          return { kind: "run", result: result || null };
        })
        .catch(function (err) {
          return { kind: "run-error", error: err };
        }),
      queueWatch.promise.then(function (watchInfo) {
        return { kind: "watch", info: watchInfo || null };
      })
    ])
      .then(function (outcome) {
        if (!outcome) {
          return null;
        }
        if (outcome.kind === "run-error") {
          runError = outcome.error;
          if (queueWatch && isRetriableRequestError(runError)) {
            return queueWatch.promise.then(function (watchInfo) {
              if (applyWatchInfo(watchInfo)) {
                runError = null;
              }
              return null;
            });
          }
          return null;
        }
        if (outcome.kind === "watch" && outcome.info) {
          applyWatchInfo(outcome.info);
          return null;
        }
        runResult = outcome.result || null;
        return null;
      })
      .then(function () {
        if (queueFinalizeApplied) {
          return null;
        }
        if (runError) {
          finalStatus = "error";
        } else if (runResult && runResult.awaitingDecision) {
          finalStatus = "awaiting_decision";
        } else if (runResult && runResult.awaitingApproval) {
          finalStatus = "awaiting_approval";
        } else {
          finalStatus = "done";
        }
        finalErrorText = runError && runError.message ? runError.message : "";
        return queueFinish(workspaceId, conversationId, itemId, finalStatus, finalErrorText).then(function (response) {
          queueFinalizeApplied = true;
          return response;
        }).catch(function (queueErr) {
          showError(queueErr);
          setConversationQueueFields(workspaceId, conversationId, {
            running: false,
            done: finalStatus === "done",
            lastStatus: finalStatus
          });
          return null;
        });
      })
      .finally(function () {
        if (queueWatch) {
          queueWatch.stop();
        }
        if (!queueFinalizeApplied) {
          setConversationQueueFields(workspaceId, conversationId, {
            running: false,
            done: finalStatus === "done",
            lastStatus: finalStatus
          });
        }
        finalizeAllRunningEvents(
          conversationId,
          finalStatus,
          finalStatus === "error" ? finalErrorText || "Run did not complete." : finalErrorText
        );
        setBusy(false);
        renderUi();
        loadState()
          .catch(function () {
            return null;
          })
          .then(function () {
            if (state.activeWorkspaceId && state.activeConversationId) {
              return loadConversation({ timeoutMs: 6000 }).catch(function () {
                return null;
              });
            }
            return null;
          })
          .finally(function () {
            renderUi();
          });
      });
  }

  function drainQueuedRuns() {
    if (state.busy) {
      return clearStaleBusyIfNeeded().then(function (cleared) {
        if (cleared) {
          return drainQueuedRuns();
        }
        return null;
      });
    }

    var target = findNextQueuedConversation();
    if (!target) {
      return Promise.resolve();
    }

    return apiPost("queue_take", {
      workspace_id: target.workspaceId,
      conversation_id: target.conversationId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not fetch queued message");
      }

      if (response.busy) {
        applyQueueStateFromResponse(target.workspaceId, target.conversationId, response);
        return null;
      }

      if (!response.has_item || !response.item) {
        applyQueueStateFromResponse(target.workspaceId, target.conversationId, response);
        return loadState().then(function () {
          return drainQueuedRuns();
        });
      }

      setConversationQueueFields(target.workspaceId, target.conversationId, {
        pending: queueNumber(response.queue_pending),
        running: true,
        done: false,
        firstId: response.queue_first_id || ""
      });

      return executeQueuedItem(target.workspaceId, target.conversationId, response.item).then(function () {
        return drainQueuedRuns();
      });
    });
  }

  function clearStaleBusyIfNeeded() {
    if (!state.busy) {
      return Promise.resolve(false);
    }
    return apiGet("state", {}, { timeoutMs: 9000 })
      .then(function (response) {
        var workspaces = response && Array.isArray(response.workspaces) ? response.workspaces : [];
        var hasQueueRunning = false;
        for (var i = 0; i < workspaces.length; i += 1) {
          var workspace = workspaces[i] || {};
          var conversations = Array.isArray(workspace.conversations) ? workspace.conversations : [];
          for (var j = 0; j < conversations.length; j += 1) {
            if (String(conversations[j] && conversations[j].queue_running || "0") === "1") {
              hasQueueRunning = true;
              break;
            }
          }
          if (hasQueueRunning) {
            break;
          }
        }
        if (!hasQueueRunning) {
          setBusy(false);
          return true;
        }
        return false;
      })
      .catch(function () {
        return false;
      });
  }

  function stopApprovalResumeWatch() {
    if (approvalResumeWatchTimer) {
      clearInterval(approvalResumeWatchTimer);
      approvalResumeWatchTimer = null;
    }
    approvalResumeWatchBusy = false;
    approvalResumeWatchKey = "";
    approvalResumeWatchDeadline = 0;
  }

  function startApprovalResumeWatch(workspaceId, conversationId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return;
    }

    stopApprovalResumeWatch();
    var watchKey = conversationReadKey(wsId, convId);
    approvalResumeWatchKey = watchKey;
    approvalResumeWatchDeadline = Date.now() + 90000;

    function tick() {
      if (
        approvalResumeWatchKey !== watchKey ||
        approvalResumeWatchBusy
      ) {
        return;
      }
      if (Date.now() > approvalResumeWatchDeadline) {
        stopApprovalResumeWatch();
        return;
      }

      approvalResumeWatchBusy = true;
      apiGet("state", {}, { timeoutMs: 9000 })
        .then(function (response) {
          if (approvalResumeWatchKey !== watchKey) {
            return;
          }

          var conversation = findConversationStateEntry(response, wsId, convId);
          if (!conversation) {
            return;
          }

          var pending = queueNumber(conversation.queue_pending);
          var running = String(conversation.queue_running || "0") === "1";
          syncConversationQueueFromStateEntry(wsId, convId, conversation);
          releaseApprovalAnswerUiPendingIfAdvanced(wsId, convId, conversation);

          if (pending > 0 && !running && !state.busy) {
            state.queueWorkerActive = false;
            kickQueueWorker();
            return;
          }

          if (running || pending > 0) {
            return;
          }

          if (
            state.busy &&
            String(state.runningWorkspaceId || "") === wsId &&
            String(state.runningConversationId || "") === convId
          ) {
            setBusy(false);
          }

          if (
            state.activeWorkspaceId === wsId &&
            state.activeConversationId === convId
          ) {
            loadConversation({ timeoutMs: 6000 }).catch(function () {
              return null;
            });
            renderUi();
            stopApprovalResumeWatch();
            return;
          }

          renderUi();
          stopApprovalResumeWatch();
        })
        .catch(function () {
          return null;
        })
        .finally(function () {
          approvalResumeWatchBusy = false;
        });
    }

    approvalResumeWatchTimer = setInterval(tick, 1200);
    tick();
  }

  function resumeConversationQueueNow(workspaceId, conversationId) {
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return Promise.resolve(false);
    }

    if (state.busy) {
      return clearStaleBusyIfNeeded().then(function (cleared) {
        if (!cleared && state.busy) {
          return false;
        }
        return resumeConversationQueueNow(wsId, convId);
      });
    }

    return apiPost("queue_take", {
      workspace_id: wsId,
      conversation_id: convId
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not resume queued run");
      }
      applyQueueStateFromResponse(wsId, convId, response);
      if (response.busy || !response.has_item || !response.item) {
        return false;
      }
      setConversationQueueFields(wsId, convId, {
        pending: queueNumber(response.queue_pending),
        running: true,
        done: false,
        firstId: response.queue_first_id || "",
        lastStatus: "running"
      });
      return executeQueuedItem(wsId, convId, response.item, { approvalRetry: true }).then(function () {
        return true;
      });
    });
  }

  function kickQueueWorker() {
    if (state.queueWorkerActive) {
      return;
    }

    if (!findNextQueuedConversation()) {
      return;
    }

    state.queueWorkerActive = true;
    drainQueuedRuns()
      .catch(function (err) {
        if (state.activeConversationId) {
          showError(err);
        } else if (window && window.console && typeof window.console.error === "function") {
          window.console.error(err);
        }
      })
      .finally(function () {
        state.queueWorkerActive = false;
        renderUi();
        if (!state.busy && findNextQueuedConversation()) {
          window.setTimeout(function () {
            kickQueueWorker();
          }, 120);
        }
      });
  }

  function steerQueuedMessage(queueItemId, options) {
    var opts = options || {};
    var wsId = String(opts.workspaceId || state.activeWorkspaceId || "");
    var convId = String(opts.conversationId || state.activeConversationId || "");
    var itemId = trim(queueItemId || "");
    if (!wsId || !convId || !itemId) {
      return Promise.resolve();
    }

    return apiPost("queue_steer", {
      workspace_id: wsId,
      conversation_id: convId,
      item_id: itemId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not steer queued message");
      }
      applyQueueStateFromResponse(wsId, convId, response);
      if (isQueueEditForConversation(wsId, convId) && String(state.queueEdit.itemId || "") === itemId) {
        clearQueueEditState();
      }
      return loadQueueItems(wsId, convId, { force: true, minIntervalMs: 0 }).catch(function () {
        return null;
      }).then(function () {
        if (opts.interruptRunning && queueStatsForConversation(wsId, convId).running) {
          return stopConversationRun(wsId, convId, { suppressNotice: true }).then(function () {
            showTransientNotice("Steered message injected");
            kickQueueWorker();
          });
        }
        renderUi();
        kickQueueWorker();
        return null;
      });
    });
  }

  function cancelQueuedMessage(queueItemId, options) {
    var opts = options || {};
    var wsId = String(opts.workspaceId || state.activeWorkspaceId || "");
    var convId = String(opts.conversationId || state.activeConversationId || "");
    var itemId = trim(queueItemId || "");
    if (!wsId || !convId || !itemId) {
      return Promise.resolve();
    }

    return apiPost("queue_cancel", {
      workspace_id: wsId,
      conversation_id: convId,
      item_id: itemId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not cancel queued message");
      }
      if (response.item_id && state.lastQueuedItemIdByConversation[convId] === response.item_id) {
        delete state.lastQueuedItemIdByConversation[convId];
      }
      applyQueueStateFromResponse(wsId, convId, response);
      if (isQueueEditForConversation(wsId, convId) && String(state.queueEdit.itemId || "") === String(response.item_id || itemId)) {
        clearQueueEditState();
      }
      return loadQueueItems(wsId, convId, { force: true, minIntervalMs: 0 }).catch(function () {
        return null;
      }).then(function () {
        renderUi();
        kickQueueWorker();
        return null;
      });
    });
  }

  function updateQueuedMessage(queueItemId, promptText, options) {
    var opts = options || {};
    var wsId = String(opts.workspaceId || state.activeWorkspaceId || "");
    var convId = String(opts.conversationId || state.activeConversationId || "");
    var itemId = trim(queueItemId || "");
    var nextPrompt = String(promptText || "");
    if (!wsId || !convId || !itemId) {
      return Promise.resolve();
    }
    if (!trim(nextPrompt)) {
      return Promise.reject(new Error("Queued message cannot be empty."));
    }
    return apiPost("queue_update", {
      workspace_id: wsId,
      conversation_id: convId,
      item_id: itemId,
      prompt: nextPrompt
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not update queued message");
      }
      applyQueueStateFromResponse(wsId, convId, response);
      return loadQueueItems(wsId, convId, { force: true, minIntervalMs: 0 }).catch(function () {
        return null;
      }).then(function () {
        return response;
      });
    });
  }

  function stopConversationRun(workspaceId, conversationId, options) {
    var opts = options || {};
    var wsId = String(workspaceId || "");
    var convId = String(conversationId || "");
    if (!wsId || !convId) {
      return Promise.resolve();
    }

    return apiPost("queue_stop", {
      workspace_id: wsId,
      conversation_id: convId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not stop run");
      }

      if (state.busy && state.runningWorkspaceId === wsId && state.runningConversationId === convId) {
        setBusy(false);
      }
      setAwaitingApprovalState(wsId, convId, false);
      applyQueueStateFromResponse(wsId, convId, response);
      finalizeLatestRunningEvent(convId, "cancelled", "");

      return loadState()
        .catch(function () {
          return null;
        })
        .then(function () {
          if (state.activeWorkspaceId === wsId && state.activeConversationId === convId) {
            return loadConversation().catch(function () {
              return null;
            });
          }
          return null;
        })
        .then(function () {
          if (!opts.suppressNotice) {
            showTransientNotice("Run stopped");
          }
          renderUi();
        });
    });
  }

  function stopTerminalPolling() {
    if (terminalPollTimer) {
      clearInterval(terminalPollTimer);
      terminalPollTimer = null;
    }
    terminalPollBusy = false;
  }

  function appendTerminalDelta(deltaText) {
    var delta = String(deltaText || "");
    if (!delta) {
      return;
    }
    var next = String(state.terminalStreamText || "") + delta;
    if (next.length > 220000) {
      next = next.slice(next.length - 220000);
    }
    state.terminalStreamText = next;
  }

  function pollTerminalSessionOnce() {
    if (!state.terminalOpen || terminalPollBusy) {
      return Promise.resolve();
    }
    var workspaceId = String(state.activeWorkspaceId || "");
    var sessionId = String(state.terminalSessionId || "");
    if (!workspaceId || !sessionId) {
      return Promise.resolve();
    }
    terminalPollBusy = true;
    return apiGet("terminal_session_poll", {
      workspace_id: workspaceId,
      session_id: sessionId,
      offset: String(Number(state.terminalStreamOffset || 0))
    }, { timeoutMs: 12000 })
      .then(function (response) {
        if (!response || !response.success) {
          return;
        }
        if (response.session_changed) {
          state.terminalSessionId = "";
          state.terminalSessionWorkspaceId = "";
          stopTerminalPolling();
          return;
        }
        appendTerminalDelta(response.delta || "");
        state.terminalStreamOffset = Number(response.offset || state.terminalStreamOffset || 0);
        renderTerminal();
      })
      .catch(function () {
        return null;
      })
      .finally(function () {
        terminalPollBusy = false;
      });
  }

  function ensureTerminalSession() {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }
    if (
      state.terminalSessionId &&
      state.terminalSessionWorkspaceId &&
      state.terminalSessionWorkspaceId === state.activeWorkspaceId
    ) {
      return Promise.resolve(state.terminalSessionId);
    }
    stopTerminalPolling();
    state.terminalSessionId = "";
    state.terminalSessionWorkspaceId = "";
    state.terminalStreamText = "";
    state.terminalStreamOffset = 0;
    state.terminalInputBuffer = "";
    renderTerminal();

    if (terminalSessionStartPromise) {
      return terminalSessionStartPromise;
    }

    terminalSessionStartPromise = apiPost("terminal_session_start", {
      workspace_id: state.activeWorkspaceId
    }, { timeoutMs: 15000 }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not start terminal session");
      }
      state.terminalSessionId = String(response.session_id || "");
      state.terminalSessionWorkspaceId = state.activeWorkspaceId;
      state.terminalStreamText = String(response.delta || "");
      state.terminalStreamOffset = Number(response.offset || 0);
      renderTerminal();
      terminalPollTimer = setInterval(function () {
        pollTerminalSessionOnce();
      }, 220);
      return state.terminalSessionId;
    }).finally(function () {
      terminalSessionStartPromise = null;
    });

    return terminalSessionStartPromise;
  }

  function runCommandViaApi(commandText, actionName) {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }

    var trimmedCommand = trim(commandText);
    if (!trimmedCommand) {
      return Promise.reject(new Error("Command is required."));
    }

    state.terminalBusy = true;
    appendTerminalLine("$ " + trimmedCommand);

    return apiPost(actionName || "terminal_exec", {
      workspace_id: state.activeWorkspaceId,
      command: commandText,
      permission_mode: state.permissionMode
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Command failed");
      }

      var output = String(response.output || "");
      if (trim(output)) {
        appendTerminalLine(output);
      }
      appendTerminalLine("[exit " + Number(response.exit_code || 0) + "]");

      return refreshGitStatus()
        .catch(function () {
          return null;
        })
        .then(function () {
          return refreshBranches().catch(function () {
            return null;
          });
        })
        .then(function () {
          if (state.diffOpen) {
            return refreshDiff().catch(function () {
              return null;
            });
          }
          return null;
        })
        .then(function () {
          renderUi();
        });
    }).finally(function () {
      state.terminalBusy = false;
      renderTerminal();
    });
  }

  function showError(error) {
    var message = error && error.message ? error.message : String(error);
    var now = Date.now();
    if (state.lastErrorText === message && now - state.lastErrorAt < 1800) {
      return;
    }
    if (
      !state.initialLoadComplete &&
      !state.activeConversationId &&
      !state.terminalOpen &&
      isRetriableRequestError(error)
    ) {
      if (window && window.console && typeof window.console.warn === "function") {
        window.console.warn("Artificer startup retry:", message);
      }
      return;
    }
    state.lastErrorText = message;
    state.lastErrorAt = now;
    if (state.activeConversationId) {
      pushRunEvent(state.activeConversationId, {
        status: "error",
        error: message,
        finished_at: new Date().toISOString()
      });
    } else if (state.terminalOpen) {
      appendTerminalLine("Error: " + message);
    }
    renderUi();
  }

  function openCommitModal(defaultAction) {
    var gitState = activeGitState();
    state.commitModalDefault = defaultAction || "commit";
    el.commitBranchLabel.textContent = gitState.branch || "-";
    el.commitChangesLabel.innerHTML = gitDeltaMarkup(gitState.added, gitState.deleted);
    el.commitIncludeUnstaged.checked = true;
    el.commitMessage.value = "";
    el.commitNextStep.value = state.commitModalDefault === "commit-push" ? "commit-push" : "commit";
    openModal(el.commitModal);
  }

  function performOpenTarget(target) {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }
    if (target !== "finder" && target !== "terminal" && target !== "textmate") {
      target = "finder";
    }
    state.lastOpenTarget = target;
    storageSet("artificer.lastOpenTarget", target);
    renderUi();
    return apiPost("open_in", {
      workspace_id: state.activeWorkspaceId,
      target: target
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Open failed");
      }
      closeAllMenus();
      return response;
    });
  }

  function createRepoForActiveWorkspace() {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }
    return apiPost("git_init", { workspace_id: state.activeWorkspaceId })
      .then(function (response) {
        if (!response.success) {
          throw new Error(response.error || "git init failed");
        }
        appendTerminalLine(response.message || "Git repository created.");
        return refreshGitStatus();
      })
      .then(function () {
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        showTransientNotice("Repository created");
        renderUi();
      });
  }

  function performCommitAction(action) {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }
    if (action !== "commit" && action !== "push" && action !== "commit-push") {
      action = "commit";
    }
    state.lastCommitAction = action;
    storageSet("artificer.lastCommitAction", action);
    renderUi();

    var gitState = activeGitState();
    if (!gitState.is_repo) {
      if (!window.confirm("This project is not a git repo yet. Create one now?")) {
        return Promise.resolve();
      }
      return createRepoForActiveWorkspace().then(function () {
        return performCommitAction(action);
      });
    }

    if (action === "push") {
      return apiPost("git_push", { workspace_id: state.activeWorkspaceId })
        .then(function (response) {
          if (!response.success) {
            throw new Error(response.error || "Push failed");
          }
          appendTerminalLine(response.output || "Push complete.");
          return refreshGitStatus();
        })
        .then(function () {
          return refreshBranches().catch(function () {
            return null;
          });
        })
        .then(function () {
          closeAllMenus();
          renderUi();
        });
    }

    closeAllMenus();
    openCommitModal(action === "commit-push" ? "commit-push" : "commit");
    return Promise.resolve();
  }

  function loadAuthStatus() {
    if (el.ghAuthStatus) {
      el.ghAuthStatus.textContent = "Checking...";
    }
    if (el.sshKeyStatus) {
      el.sshKeyStatus.textContent = "Checking...";
    }

    return apiGet("git_auth_status", {}, { timeoutMs: 12000 }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load auth status");
      }

      if (response.has_gh) {
        el.ghAuthStatus.textContent = response.gh_authenticated ? "Authenticated" : "Not authenticated";
      } else {
        el.ghAuthStatus.textContent = "GitHub CLI not installed";
      }

      if (response.ssh_pub_exists) {
        el.sshKeyStatus.textContent = "SSH key found";
        el.sshPubOutput.value = response.ssh_pub_key || "";
      } else {
        el.sshKeyStatus.textContent = "No SSH key";
        el.sshPubOutput.value = "";
      }

      if (el.selectedSshPath) {
        if (response.selected_ssh_pub_path) {
          el.selectedSshPath.value = response.selected_ssh_pub_path;
        } else {
          el.selectedSshPath.value = "";
          el.selectedSshPath.placeholder = "Using auto-detected SSH key.";
        }
      }
    }).catch(function (error) {
      if (el.ghAuthStatus) {
        el.ghAuthStatus.textContent = "Unavailable";
      }
      if (el.sshKeyStatus) {
        el.sshKeyStatus.textContent = "Unavailable";
      }
      if (el.sshPubOutput) {
        el.sshPubOutput.value = "";
      }
      if (el.selectedSshPath) {
        el.selectedSshPath.value = "";
        el.selectedSshPath.placeholder = "Could not load SSH key status.";
      }
      throw error;
    });
  }

  function loadModeRuntimeState() {
    state.modeRuntimeLoading = true;
    return apiGet("mode_runtime_state", {}, { timeoutMs: 12000 })
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Failed to load mode runtime state");
        }
        state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
        reconcileAssistantModeId();
        state.modeRuntimeError = "";
        return state.modeRuntime;
      })
      .catch(function (error) {
        state.modeRuntimeError = error && error.message ? error.message : "Mode runtime unavailable";
        return null;
      })
      .finally(function () {
        state.modeRuntimeLoading = false;
        renderModeRuntimeSettings();
      });
  }

  function modeRuntimeUpdate(modeId, patch) {
    var id = trim(String(modeId || ""));
    if (!id) {
      return Promise.resolve(null);
    }
    var payload = {
      mode_id: id
    };
    var source = patch && typeof patch === "object" ? patch : {};
    if (typeof source.enabled !== "undefined") {
      payload.enabled = source.enabled ? "1" : "0";
    }
    if (typeof source.priority !== "undefined") {
      payload.priority = String(source.priority);
    }
    if (typeof source.cadence_sec !== "undefined") {
      payload.cadence_sec = String(source.cadence_sec);
    }
    if (typeof source.interrupt_rights !== "undefined") {
      payload.interrupt_rights = source.interrupt_rights ? "1" : "0";
    }
    if (typeof source.allow_queue_injection !== "undefined") {
      payload.allow_queue_injection = source.allow_queue_injection ? "1" : "0";
    }
    if (typeof source.goal_state !== "undefined") {
      payload.goal_state = String(source.goal_state || "");
    }
    if (typeof source.subscriptions !== "undefined") {
      payload.subscriptions = String(source.subscriptions || "");
    }

    state.modeRuntimeLoading = true;
    renderModeRuntimeSettings();
    return apiPost("mode_runtime_update", payload)
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Could not update mode runtime");
        }
        state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
        reconcileAssistantModeId();
        state.modeRuntimeError = "";
        return response;
      })
      .catch(function (error) {
        state.modeRuntimeError = error && error.message ? error.message : "Could not update mode runtime";
        throw error;
      })
      .finally(function () {
        state.modeRuntimeLoading = false;
        renderModeRuntimeSettings();
      });
  }

  function modeRuntimeTickNow() {
    state.modeRuntimeLoading = true;
    renderModeRuntimeSettings();
    return apiPost("mode_runtime_tick", {
      workspace_id: state.activeWorkspaceId || "",
      conversation_id: state.activeConversationId || ""
    })
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Mode runtime tick failed");
        }
        state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
        reconcileAssistantModeId();
        state.modeRuntimeError = "";
        return response;
      })
      .catch(function (error) {
        state.modeRuntimeError = error && error.message ? error.message : "Mode runtime tick failed";
        throw error;
      })
      .finally(function () {
        state.modeRuntimeLoading = false;
        renderModeRuntimeSettings();
      });
  }

  function setModeRuntimeSkillResult(text, isError) {
    if (!el.modeRuntimeSkillResult) {
      return;
    }
    var clean = trim(String(text || ""));
    if (!clean) {
      el.modeRuntimeSkillResult.textContent = "";
      el.modeRuntimeSkillResult.classList.add("hidden");
      el.modeRuntimeSkillResult.classList.remove("error");
      return;
    }
    el.modeRuntimeSkillResult.textContent = clean;
    el.modeRuntimeSkillResult.classList.remove("hidden");
    el.modeRuntimeSkillResult.classList.toggle("error", !!isError);
  }

  function modeRuntimeSkillInvoke(modeId, skillId, inputText, capabilitiesCsv) {
    return apiPost("mode_runtime_skill_invoke", {
      mode_id: trim(String(modeId || "")),
      skill_id: trim(String(skillId || "")),
      input: String(inputText || ""),
      capabilities: trim(String(capabilitiesCsv || ""))
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Skill invocation failed");
      }
      var result = response.result && typeof response.result === "object" ? response.result : {};
      var summary = trim(String(result.summary || ""));
      var actions = Array.isArray(result.actions) ? result.actions : [];
      var notes = trim(String(result.notes || ""));
      var lines = [];
      lines.push("skill_id: " + String(result.skill_id || skillId));
      lines.push("status: " + String(result.status || "ok"));
      if (summary) {
        lines.push("summary: " + summary);
      }
      if (actions.length) {
        lines.push("actions:");
        for (var i = 0; i < actions.length; i += 1) {
          lines.push("- " + String(actions[i] || ""));
        }
      }
      if (notes) {
        lines.push("notes: " + notes);
      }
      setModeRuntimeSkillResult(lines.join("\n"), false);
      return response;
    });
  }

  function modeRuntimeSkillCreate(payload) {
    var source = payload && typeof payload === "object" ? payload : {};
    return apiPost("mode_runtime_skill_create", {
      skill_id: trim(String(source.skill_id || "")),
      name: trim(String(source.name || "")),
      trigger: trim(String(source.trigger || "")),
      capabilities: trim(String(source.capabilities || "")),
      description: trim(String(source.description || ""))
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not create skill");
      }
      state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
      reconcileAssistantModeId();
      state.modeRuntimeError = "";
      renderModeRuntimeSettings();
      return response;
    });
  }

  function modeRuntimeSkillInstall(payload) {
    var source = payload && typeof payload === "object" ? payload : {};
    return apiPost("mode_runtime_skill_install", {
      source_path: trim(String(source.source_path || "")),
      skill_id: trim(String(source.skill_id || "")),
      replace: source.replace ? "1" : "0"
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not install skill");
      }
      state.modeRuntime = normalizeModeRuntime(response.mode_runtime);
      reconcileAssistantModeId();
      state.modeRuntimeError = "";
      renderModeRuntimeSettings();
      return response;
    });
  }

  function renderModeRuntimeSettings() {
    if (!el.modeRuntimeSummary || !el.modeRuntimePanels || !el.modeRuntimeModes || !el.modeRuntimeSkills) {
      return;
    }

    var runtime = normalizeModeRuntime(state.modeRuntime);
    var scheduler = runtime.scheduler || {};
    var cooperation = runtime.cooperation || {};
    var summary = "Scheduler ticks: " + (scheduler.ticks || "0");
    if (scheduler.last_tick_iso) {
      summary += " | last tick: " + scheduler.last_tick_iso;
    }
    summary += " | directives in/out: " + (scheduler.last_directives_received || "0") + "/" + (scheduler.last_directives_emitted || "0");
    if (String(cooperation.pending_total || "0") !== "0") {
      summary += " | pending directives: " + String(cooperation.pending_total || "0");
    }
    if (scheduler.summary) {
      summary += " | " + scheduler.summary;
    }
    if (state.modeRuntimeLoading) {
      summary = "Loading Mode Runtime...";
    } else if (state.modeRuntimeError) {
      summary = state.modeRuntimeError;
    }
    el.modeRuntimeSummary.textContent = summary;

    var panelsHtml = "";
    var panels = Array.isArray(runtime.panels) ? runtime.panels : [];
    var recentDirectives = Array.isArray(cooperation.recent) ? cooperation.recent : [];
    var cooperationPanelHtml = "<section class='mode-runtime-panel mode-runtime-cooperation-panel'>";
    cooperationPanelHtml += "<div class='mode-runtime-panel-head'><strong>Mode Cooperation</strong></div>";
    cooperationPanelHtml += "<p class='settings-hint'>Directive bus for mode-to-mode governance handoffs and coordination.</p>";
    cooperationPanelHtml += "<div class='mode-runtime-metrics'>";
    cooperationPanelHtml += "<span class='mode-runtime-metric'><em>Pending</em><strong>" + escHtml(String(cooperation.pending_total || "0")) + "</strong></span>";
    cooperationPanelHtml += "<span class='mode-runtime-metric'><em>Modes waiting</em><strong>" + escHtml(String(cooperation.modes_with_pending || "0")) + "</strong></span>";
    cooperationPanelHtml += "<span class='mode-runtime-metric'><em>In / Out</em><strong>" + escHtml(String(scheduler.last_directives_received || "0") + " / " + String(scheduler.last_directives_emitted || "0")) + "</strong></span>";
    cooperationPanelHtml += "</div>";
    if (!recentDirectives.length) {
      cooperationPanelHtml += "<p class='settings-hint'>No recent cross-mode directives.</p>";
    } else {
      cooperationPanelHtml += "<div class='mode-runtime-directive-list'>";
      for (var r = 0; r < recentDirectives.length && r < 10; r += 1) {
        var directive = recentDirectives[r] || {};
        var fromMode = trim(String(directive.from_mode || "mode"));
        var toMode = trim(String(directive.to_mode || "mode"));
        var kind = trim(String(directive.kind || "note"));
        var payload = trim(String(directive.payload || ""));
        var stamp = trim(String(directive.timestamp || ""));
        var prefix = fromMode + " -> " + toMode + " [" + kind + "]";
        if (directive.expired) {
          prefix += " (expired)";
        }
        cooperationPanelHtml += "<p class='settings-hint mode-runtime-directive-item'><strong>" + escHtml(prefix) + "</strong>";
        if (payload) {
          cooperationPanelHtml += " " + escHtml(payload);
        }
        if (stamp) {
          cooperationPanelHtml += " <span class='mode-runtime-directive-time'>" + escHtml(stamp) + "</span>";
        }
        cooperationPanelHtml += "</p>";
      }
      cooperationPanelHtml += "</div>";
    }
    cooperationPanelHtml += "</section>";
    if (!panels.length) {
      panelsHtml = cooperationPanelHtml + "<p class='empty-state'>No runtime panels available yet.</p>";
    } else {
      panelsHtml += cooperationPanelHtml;
      for (var i = 0; i < panels.length; i += 1) {
        var panel = panels[i] || {};
        var metrics = Array.isArray(panel.metrics) ? panel.metrics : [];
        panelsHtml += "<section class='mode-runtime-panel'>";
        panelsHtml += "<div class='mode-runtime-panel-head'><strong>" + escHtml(panel.title || panel.id || "Panel") + "</strong></div>";
        if (panel.summary) {
          panelsHtml += "<p class='settings-hint'>" + escHtml(panel.summary) + "</p>";
        }
        if (metrics.length) {
          panelsHtml += "<div class='mode-runtime-metrics'>";
          for (var m = 0; m < metrics.length; m += 1) {
            var metric = metrics[m] || {};
            panelsHtml += "<span class='mode-runtime-metric'><em>" + escHtml(metric.label || "Metric") + "</em><strong>" + escHtml(metric.value || "") + "</strong></span>";
          }
          panelsHtml += "</div>";
        }
        if (panel.stream) {
          panelsHtml += "<p class='settings-hint'>" + escHtml(panel.stream) + "</p>";
        }
        panelsHtml += "</section>";
      }
    }
    el.modeRuntimePanels.innerHTML = panelsHtml;

    var modes = Array.isArray(runtime.modes) ? runtime.modes : [];
    var modesHtml = "";
    if (!modes.length) {
      modesHtml = "<p class='empty-state'>No Modes configured.</p>";
    } else {
      modesHtml += "<section class='mode-runtime-group'><div class='mode-runtime-group-head'><p class='command-rules-group-title'>Modes</p></div>";
      for (var j = 0; j < modes.length; j += 1) {
        var mode = modes[j] || {};
        var modeId = String(mode.id || "");
        if (!modeId) {
          continue;
        }
        var enabledLabel = mode.enabled ? "Disable" : "Enable";
        var enabledNext = mode.enabled ? "0" : "1";
        var injectLabel = mode.allow_queue_injection ? "Queue injection: On" : "Queue injection: Off";
        var injectNext = mode.allow_queue_injection ? "0" : "1";
        var driftValue = trim(String(mode.drift_score || "0.00"));
        var directiveInValue = trim(String(mode.last_directive_count || "0"));
        var directiveOutValue = trim(String(mode.last_directive_emits || "0"));
        var directiveSummaryValue = trim(String(mode.last_directive_summary || "none"));
        var cadenceValue = queueNumber(mode.cadence_sec || 0);
        var priorityValue = queueNumber(mode.priority || 0);
        modesHtml += "<article class='mode-runtime-mode'>";
        modesHtml += "<div class='mode-runtime-mode-head'><strong>" + escHtml(mode.name || modeId) + "</strong><span class='mode-runtime-chip'>" + escHtml(mode.status || "idle") + "</span></div>";
        if (mode.description) {
          modesHtml += "<p class='settings-hint'>" + escHtml(mode.description) + "</p>";
        }
        modesHtml += "<p class='settings-hint'>drift " + escHtml(driftValue) + " | cadence " + escHtml(String(cadenceValue || 0)) + "s | priority " + escHtml(String(priorityValue || 0)) + "</p>";
        modesHtml += "<p class='settings-hint'>directives in " + escHtml(directiveInValue) + " | out " + escHtml(directiveOutValue) + "</p>";
        if (directiveSummaryValue && directiveSummaryValue !== "none") {
          modesHtml += "<p class='settings-hint'>latest directive context: " + escHtml(directiveSummaryValue) + "</p>";
        }
        modesHtml += "<div class='mode-runtime-actions'>";
        modesHtml += "<button type='button' data-action='mode-runtime-use' data-mode-id='" + escAttr(modeId) + "'>Use in Assistant</button>";
        modesHtml += "<button type='button' data-action='mode-runtime-toggle' data-mode-id='" + escAttr(modeId) + "' data-enabled='" + escAttr(enabledNext) + "'>" + escHtml(enabledLabel) + "</button>";
        modesHtml += "<button type='button' data-action='mode-runtime-injection' data-mode-id='" + escAttr(modeId) + "' data-allow='" + escAttr(injectNext) + "'>" + escHtml(injectLabel) + "</button>";
        modesHtml += "</div>";
        modesHtml += "</article>";
      }
      modesHtml += "</section>";
    }
    el.modeRuntimeModes.innerHTML = modesHtml;

    var skills = Array.isArray(runtime.skills) ? runtime.skills : [];
    var skillsHtml = "";
    if (!skills.length) {
      skillsHtml = "<p class='empty-state'>No Skills configured.</p>";
    } else {
      skillsHtml += "<section class='mode-runtime-group'><div class='mode-runtime-group-head'><p class='command-rules-group-title'>Skills</p></div>";
      for (var k = 0; k < skills.length; k += 1) {
        var skill = skills[k] || {};
        var caps = Array.isArray(skill.capabilities) ? skill.capabilities : [];
        skillsHtml += "<article class='mode-runtime-skill'>";
        skillsHtml += "<div class='mode-runtime-mode-head'><strong>" + escHtml(skill.name || skill.id || "Skill") + "</strong></div>";
        if (skill.description) {
          skillsHtml += "<p class='settings-hint'>" + escHtml(skill.description) + "</p>";
        }
        if (skill.trigger) {
          skillsHtml += "<p class='settings-hint'>trigger: " + escHtml(skill.trigger) + "</p>";
        }
        var fileBadges = [];
        if (skill.files && typeof skill.files === "object") {
          if (skill.files.policy_md) {
            fileBadges.push("policy.md");
          }
          if (skill.files.trigger_yaml) {
            fileBadges.push("trigger.yaml");
          }
          if (skill.files.tools_json) {
            fileBadges.push("tools.json");
          }
          if (skill.files.output_schema_json) {
            fileBadges.push("output.schema.json");
          }
        }
        skillsHtml += "<p class='settings-hint'>capabilities: " + escHtml(caps.join(", ") || "none") + " | stateless actuator | interrupt authority: " + (skill.interrupt_authority ? "yes" : "no") + "</p>";
        if (fileBadges.length) {
          skillsHtml += "<p class='settings-hint'>bundle files: " + escHtml(fileBadges.join(", ")) + "</p>";
        }
        skillsHtml += "<div class='mode-runtime-actions'><button type='button' data-action='mode-runtime-skill-quick' data-skill-id='" + escAttr(skill.id || "") + "'>Use skill</button></div>";
        skillsHtml += "</article>";
      }
      skillsHtml += "</section>";
    }
    el.modeRuntimeSkills.innerHTML = skillsHtml;

    if (el.assistantModeSelect) {
      var assistantValue = normalizeAssistantModeId(state.assistantModeId);
      var assistantOptions = "<option value=''>Assistant (General)</option>";
      for (var a = 0; a < modes.length; a += 1) {
        var modeOption = modes[a] || {};
        var optionId = trim(String(modeOption.id || ""));
        if (!optionId) {
          continue;
        }
        assistantOptions += "<option value='" + escAttr(optionId) + "'>" + escHtml(modeOption.name || optionId) + "</option>";
      }
      if (el.assistantModeSelect.innerHTML !== assistantOptions) {
        el.assistantModeSelect.innerHTML = assistantOptions;
      }
      el.assistantModeSelect.value = assistantValue;
      if (el.assistantModeSelect.value !== assistantValue) {
        el.assistantModeSelect.value = "";
      }
    }

    if (el.modeRuntimeSkillMode) {
      var modeSelectOptions = "<option value='assistant'>assistant (manual)</option>";
      for (var b = 0; b < modes.length; b += 1) {
        var modeEntry = modes[b] || {};
        var modeEntryId = trim(String(modeEntry.id || ""));
        if (!modeEntryId) {
          continue;
        }
        modeSelectOptions += "<option value='" + escAttr(modeEntryId) + "'>" + escHtml(modeEntry.name || modeEntryId) + "</option>";
      }
      if (el.modeRuntimeSkillMode.innerHTML !== modeSelectOptions) {
        el.modeRuntimeSkillMode.innerHTML = modeSelectOptions;
      }
      var hasModeSelection = false;
      for (var bm = 0; bm < el.modeRuntimeSkillMode.options.length; bm += 1) {
        if (String(el.modeRuntimeSkillMode.options[bm].value || "") === String(el.modeRuntimeSkillMode.value || "")) {
          hasModeSelection = true;
          break;
        }
      }
      if (!hasModeSelection) {
        el.modeRuntimeSkillMode.value = "assistant";
      }
    }

    if (el.modeRuntimeSkillSelect) {
      var skillOptions = "<option value=''>Select skill</option>";
      for (var c = 0; c < skills.length; c += 1) {
        var skillOption = skills[c] || {};
        var skillOptionId = trim(String(skillOption.id || ""));
        if (!skillOptionId) {
          continue;
        }
        skillOptions += "<option value='" + escAttr(skillOptionId) + "'>" + escHtml(skillOption.name || skillOptionId) + "</option>";
      }
      if (el.modeRuntimeSkillSelect.innerHTML !== skillOptions) {
        el.modeRuntimeSkillSelect.innerHTML = skillOptions;
      }
      var hasSkillSelection = false;
      for (var cs = 0; cs < el.modeRuntimeSkillSelect.options.length; cs += 1) {
        if (String(el.modeRuntimeSkillSelect.options[cs].value || "") === String(el.modeRuntimeSkillSelect.value || "")) {
          hasSkillSelection = true;
          break;
        }
      }
      if (!hasSkillSelection && skills.length) {
        el.modeRuntimeSkillSelect.value = String((skills[0] && skills[0].id) || "");
      }
    }
  }

  function openSettingsModal() {
    openModal(el.settingsModal);
    var preferredWorkspace = String(state.commandRulesWorkspaceId || state.activeWorkspaceId || "");
    if (!preferredWorkspace && state.workspaces.length) {
      preferredWorkspace = String((state.workspaces[0] && state.workspaces[0].id) || "");
    }
    state.commandRulesWorkspaceId = preferredWorkspace;
    renderCommandRulesSettings();
    return Promise.all([
      loadAuthStatus().catch(function () {
        return null;
      }),
      loadCommandRules(preferredWorkspace).catch(function () {
        return null;
      }),
      loadModeRuntimeState().catch(function () {
        return null;
      })
    ]);
  }

  function commandRuleDecisionLabel(decision) {
    var value = String(decision || "");
    if (value === "allow") {
      return "Allow";
    }
    if (value === "deny") {
      return "Deny";
    }
    return "Rule";
  }

  function commandRuleMatchModeLabel(matchMode) {
    var value = String(matchMode || "").toLowerCase();
    if (value === "regex") {
      return "regex";
    }
    return "exact";
  }

  function renderCommandRulesSettings() {
    if (!el.commandRulesWorkspace || !el.commandRulesList || !el.commandRulesGlobalList || !el.commandRulesStatus) {
      return;
    }
    var workspaceOptions = "";
    if (!state.workspaces.length) {
      workspaceOptions = "<option value=''>No projects</option>";
    } else {
      for (var i = 0; i < state.workspaces.length; i += 1) {
        var workspace = state.workspaces[i] || {};
        var wsId = String(workspace.id || "");
        if (!wsId) {
          continue;
        }
        workspaceOptions += "<option value='" + escAttr(wsId) + "'>" + escHtml(workspace.name || wsId) + "</option>";
      }
    }
    if (el.commandRulesWorkspace.innerHTML !== workspaceOptions) {
      el.commandRulesWorkspace.innerHTML = workspaceOptions;
    }
    if (state.commandRulesWorkspaceId) {
      el.commandRulesWorkspace.value = state.commandRulesWorkspaceId;
      if (el.commandRulesWorkspace.value !== state.commandRulesWorkspaceId && el.commandRulesWorkspace.options.length) {
        el.commandRulesWorkspace.value = el.commandRulesWorkspace.options[0].value;
        state.commandRulesWorkspaceId = el.commandRulesWorkspace.value;
      }
    } else if (el.commandRulesWorkspace.options.length) {
      el.commandRulesWorkspace.value = el.commandRulesWorkspace.options[0].value;
      state.commandRulesWorkspaceId = el.commandRulesWorkspace.value;
    }

    var wsId = String(state.commandRulesWorkspaceId || "");
    var rulesData = wsId ? (state.commandRulesByWorkspace[wsId] || null) : null;
    if (!rulesData && state.commandRulesLoading) {
      var fallbackWsId = String(state.commandRulesLastRenderedWorkspaceId || "");
      if (fallbackWsId) {
        rulesData = state.commandRulesByWorkspace[fallbackWsId] || null;
      }
    }
    var statusText = "";
    if (state.commandRulesLoading) {
      statusText = "Loading command rules...";
    } else if (state.commandRulesError) {
      statusText = state.commandRulesError;
    }
    el.commandRulesStatus.textContent = statusText;

    var globalHtml = "";
    var html = "";
    if (!rulesData) {
      globalHtml = "<p class='empty-state'>No command rule data available.</p>";
      html = "";
      el.commandRulesGlobalList.innerHTML = globalHtml;
      el.commandRulesList.innerHTML = html;
      return;
    }
    if (wsId && state.commandRulesByWorkspace[wsId]) {
      state.commandRulesLastRenderedWorkspaceId = wsId;
    }

    var globalDefaults = Array.isArray(rulesData.global_defaults) ? rulesData.global_defaults : [];
    var remembered = Array.isArray(rulesData.remembered) ? rulesData.remembered : [];
    var onceRules = Array.isArray(rulesData.once) ? rulesData.once : [];

    globalHtml += "<section class='command-rules-group'><div class='command-rules-group-head'><p class='command-rules-group-title'>Global defaults</p></div><p class='settings-hint'>Global defaults apply to all projects.</p>";
    if (!globalDefaults.length) {
      globalHtml += "<p class='empty-state'>No global defaults configured.</p>";
    } else {
      globalHtml += "<div class='command-rule-table command-rule-table-global'>";
      globalHtml += "<div class='command-rule-table-head'><span>Command</span><span>Regex</span></div>";
      for (var g = 0; g < globalDefaults.length; g += 1) {
        var globalRule = globalDefaults[g] || {};
        globalHtml += "<div class='command-rule-row table global locked'>";
        globalHtml += "<div class='command-rule-col command'><span class='command-rule-command-text'>" + escHtml(globalRule.label || "Safe command") + "</span></div>";
        globalHtml += "<code class='command-rule-col regex'>" + escHtml(globalRule.pattern || "") + "</code>";
        globalHtml += "</div>";
      }
      globalHtml += "</div>";
    }
    globalHtml += "</section>";

    html += "<section class='command-rules-group'><div class='command-rules-group-head'><p class='command-rules-group-title'>Remembered project rules</p>";
    if (remembered.length) {
      html += "<button type='button' class='command-rule-clear ghost' data-action='clear-command-rules' data-rule-scope='remember'>Clear</button>";
    }
    html += "</div>";
    if (!remembered.length) {
      html += "<p class='empty-state'>No remembered project rules.</p>";
    } else {
      html += "<div class='command-rule-table command-rule-table-workspace'>";
      html += "<div class='command-rule-table-head'><span>Rule</span><span>Match</span><span></span></div>";
      for (var r = 0; r < remembered.length; r += 1) {
        var rememberedRule = remembered[r] || {};
        var ruleIndex = String(rememberedRule.index || "");
        var rememberedMode = commandRuleMatchModeLabel(rememberedRule.match_mode);
        var rememberedPattern = String(rememberedRule.pattern || "");
        var rememberedRuleText = rememberedMode === "exact" ? rememberedPattern : "regex rule";
        var rememberedMatchText = rememberedMode === "regex"
          ? "<code class='command-rule-col regex'>" + escHtml(rememberedPattern) + "</code>"
          : "<span class='command-rule-mode'><em>exact</em></span>";
        html += "<div class='command-rule-row table workspace'>";
        html += "<div class='command-rule-col command'><span class='command-rule-pill'>" + escHtml(commandRuleDecisionLabel(rememberedRule.decision)) + "</span><span class='command-rule-command-text'>" + escHtml(rememberedRuleText) + "</span></div>";
        html += "<div class='command-rule-col match'>" + rememberedMatchText + "</div>";
        html += "<button type='button' class='command-rule-delete' data-action='delete-command-rule' data-rule-scope='remember' data-rule-index='" + escAttr(ruleIndex) + "' aria-label='Delete rule' title='Delete rule'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'><path d='M3.5 4.4h9'></path><path d='M6.1 4.4V3.2h3.8v1.2'></path><path d='M5.2 6.1v6'></path><path d='M8 6.1v6'></path><path d='M10.8 6.1v6'></path><path d='M4.4 4.4l.6 8.2h6l.6-8.2'></path></svg></button>";
        html += "</div>";
      }
      html += "</div>";
    }
    html += "</section>";

    html += "<section class='command-rules-group'><div class='command-rules-group-head'><p class='command-rules-group-title'>One-time project rules</p>";
    if (onceRules.length) {
      html += "<button type='button' class='command-rule-clear ghost' data-action='clear-command-rules' data-rule-scope='once'>Clear</button>";
    }
    html += "</div>";
    if (!onceRules.length) {
      html += "<p class='empty-state'>No one-time project rules.</p>";
    } else {
      html += "<div class='command-rule-table command-rule-table-workspace'>";
      html += "<div class='command-rule-table-head'><span>Rule</span><span>Match</span><span></span></div>";
      for (var o = 0; o < onceRules.length; o += 1) {
        var onceRule = onceRules[o] || {};
        var onceIndex = String(onceRule.index || "");
        var onceMode = commandRuleMatchModeLabel(onceRule.match_mode);
        var oncePattern = String(onceRule.pattern || "");
        var onceRuleText = onceMode === "exact" ? oncePattern : "regex rule";
        var onceMatchText = onceMode === "regex"
          ? "<code class='command-rule-col regex'>" + escHtml(oncePattern) + "</code>"
          : "<span class='command-rule-mode'><em>exact</em></span>";
        html += "<div class='command-rule-row table workspace'>";
        html += "<div class='command-rule-col command'><span class='command-rule-pill'>" + escHtml(commandRuleDecisionLabel(onceRule.decision)) + "</span><span class='command-rule-command-text'>" + escHtml(onceRuleText) + "</span></div>";
        html += "<div class='command-rule-col match'>" + onceMatchText + "</div>";
        html += "<button type='button' class='command-rule-delete' data-action='delete-command-rule' data-rule-scope='once' data-rule-index='" + escAttr(onceIndex) + "' aria-label='Delete rule' title='Delete rule'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'><path d='M3.5 4.4h9'></path><path d='M6.1 4.4V3.2h3.8v1.2'></path><path d='M5.2 6.1v6'></path><path d='M8 6.1v6'></path><path d='M10.8 6.1v6'></path><path d='M4.4 4.4l.6 8.2h6l.6-8.2'></path></svg></button>";
        html += "</div>";
      }
      html += "</div>";
    }
    html += "</section>";

    el.commandRulesGlobalList.innerHTML = globalHtml;
    el.commandRulesList.innerHTML = html;
  }

  function loadCommandRules(workspaceId) {
    var wsId = trim(workspaceId || "");
    var settingsCard = el.settingsModal && el.settingsModal.querySelector
      ? el.settingsModal.querySelector(".modal-card")
      : null;
    var preservedScrollTop = settingsCard ? settingsCard.scrollTop : 0;
    if (!wsId) {
      state.commandRulesError = "";
      renderCommandRulesSettings();
      if (settingsCard) {
        settingsCard.scrollTop = preservedScrollTop;
      }
      return Promise.resolve(null);
    }
    state.commandRulesWorkspaceId = wsId;
    state.commandRulesLoading = true;
    state.commandRulesError = "";
    renderCommandRulesSettings();
    if (settingsCard) {
      settingsCard.scrollTop = preservedScrollTop;
    }
    return apiGet("command_rules_list", { workspace_id: wsId })
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Could not load command rules");
        }
        state.commandRulesByWorkspace[wsId] = response;
        state.commandRulesError = "";
        return response;
      })
      .catch(function (error) {
        var message = error && error.message ? error.message : "Could not load command rules";
        if (/workspace not found/i.test(message)) {
          var nextWorkspaces = [];
          for (var i = 0; i < state.workspaces.length; i += 1) {
            var workspace = state.workspaces[i] || {};
            if (String(workspace.id || "") !== wsId) {
              nextWorkspaces.push(workspace);
            }
          }
          state.workspaces = nextWorkspaces;
          delete state.commandRulesByWorkspace[wsId];
          if (String(state.commandRulesWorkspaceId || "") === wsId) {
            state.commandRulesWorkspaceId = state.workspaces.length ? String((state.workspaces[0] && state.workspaces[0].id) || "") : "";
          }
          if (state.commandRulesWorkspaceId) {
            state.commandRulesError = "Selected project was removed. Switched to another project.";
            return loadCommandRules(state.commandRulesWorkspaceId);
          }
          state.commandRulesError = "Selected project was removed.";
          return null;
        }
        state.commandRulesError = message;
        return null;
      })
      .finally(function () {
        state.commandRulesLoading = false;
        renderCommandRulesSettings();
        if (settingsCard) {
          settingsCard.scrollTop = preservedScrollTop;
        }
      });
  }

  function deleteCommandRule(workspaceId, scope, indexValue) {
    var wsId = trim(workspaceId || "");
    var ruleScope = trim(scope || "");
    var idx = trim(String(indexValue || ""));
    if (!wsId || !ruleScope || !idx) {
      return Promise.resolve(null);
    }
    return apiPost("command_rule_delete", {
      workspace_id: wsId,
      scope: ruleScope,
      index: idx
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not delete rule");
      }
      return loadCommandRules(wsId);
    });
  }

  function clearCommandRules(workspaceId, scope) {
    var wsId = trim(workspaceId || "");
    var ruleScope = trim(scope || "");
    if (!wsId || !ruleScope) {
      return Promise.resolve(null);
    }
    return apiPost("command_rules_clear", {
      workspace_id: wsId,
      scope: ruleScope
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not clear command rules");
      }
      return loadCommandRules(wsId);
    });
  }

  function loadWorkspaceMultiAgent(workspaceId) {
    var wsId = trim(String(workspaceId || ""));
    if (!wsId) {
      return Promise.resolve(null);
    }
    state.workspaceMultiAgentLoadingById[wsId] = true;
    renderMultiAgentModal();
    return apiGet("multi_agent_workspace_get", { workspace_id: wsId })
      .then(function (response) {
        if (!response || !response.success || !response.workspace_multi_agent) {
          throw new Error((response && response.error) || "Could not load agent settings");
        }
        state.workspaceMultiAgentById[wsId] = response.workspace_multi_agent;
        state.workspaceMultiAgentErrorById[wsId] = "";
        return response.workspace_multi_agent;
      })
      .catch(function (error) {
        state.workspaceMultiAgentErrorById[wsId] = error && error.message ? error.message : "Could not load agent settings";
        throw error;
      })
      .finally(function () {
        state.workspaceMultiAgentLoadingById[wsId] = false;
        renderMultiAgentModal();
      });
  }

  function saveWorkspaceMultiAgent(workspaceId, payload) {
    var wsId = trim(String(workspaceId || ""));
    if (!wsId) {
      return Promise.resolve(null);
    }
    var body = payload && typeof payload === "object" ? payload : {};
    if (Object.prototype.hasOwnProperty.call(body, "charter")) {
      body.charter_present = "1";
    }
    body.workspace_id = wsId;
    state.workspaceMultiAgentLoadingById[wsId] = true;
    renderMultiAgentModal();
    return apiPost("multi_agent_workspace_update", body)
      .then(function (response) {
        if (!response || !response.success || !response.workspace_multi_agent) {
          throw new Error((response && response.error) || "Could not save agent settings");
        }
        state.workspaceMultiAgentById[wsId] = response.workspace_multi_agent;
        state.workspaceMultiAgentErrorById[wsId] = "";
        return response.workspace_multi_agent;
      })
      .catch(function (error) {
        state.workspaceMultiAgentErrorById[wsId] = error && error.message ? error.message : "Could not save agent settings";
        throw error;
      })
      .finally(function () {
        state.workspaceMultiAgentLoadingById[wsId] = false;
        renderMultiAgentModal();
      });
  }

  function saveMultiAgentGovernanceFromControls(workspaceId) {
    var wsId = trim(String(workspaceId || ""));
    if (!wsId) {
      return Promise.resolve(null);
    }
    var policyAmendmentsEnabled = el.multi_agentToggleAmendments && el.multi_agentToggleAmendments.checked ? "1" : "0";
    return saveWorkspaceMultiAgent(wsId, {
      dilemma_surfacing: "1",
      amendments: policyAmendmentsEnabled,
      interpretation_log: policyAmendmentsEnabled,
      commitments: el.multi_agentToggleCommitments && el.multi_agentToggleCommitments.checked ? "1" : "0",
      attention_policies: el.multi_agentTogglePolicies && el.multi_agentTogglePolicies.checked ? "1" : "0"
    });
  }

  function normalizeSharedInstructionsText(rawText) {
    var text = String(rawText || "");
    var trimmedText = trim(text);
    var legacyDefault = trim("# Workspace Charter\n\nState your intent, constraints, and governance priorities for this workspace.");
    if (trimmedText === legacyDefault) {
      return "";
    }
    return text;
  }

  function flushMultiAgentCharterSave(workspaceId) {
    var wsId = trim(String(workspaceId || ""));
    if (!wsId) {
      return Promise.resolve(null);
    }
    var charterText = normalizeSharedInstructionsText((el.multi_agentCharter && el.multi_agentCharter.value) || "");
    var current = normalizeSharedInstructionsText(state.workspaceMultiAgentById[wsId] && String(state.workspaceMultiAgentById[wsId].charter || ""));
    if (charterText === current) {
      return Promise.resolve(null);
    }
    return saveWorkspaceMultiAgent(wsId, {
      charter: charterText
    }).then(function () {
      return loadState();
    }).then(renderUi);
  }

  function scheduleMultiAgentCharterSave(workspaceId, delayMs) {
    var wsId = trim(String(workspaceId || ""));
    if (!wsId) {
      return;
    }
    var timers = state.multiAgentCharterAutosaveTimerByWorkspace;
    if (timers[wsId]) {
      clearTimeout(timers[wsId]);
      delete timers[wsId];
    }
    var waitMs = Number(delayMs || 0);
    if (!isFinite(waitMs) || waitMs < 0) {
      waitMs = 700;
    }
    timers[wsId] = setTimeout(function () {
      delete timers[wsId];
      flushMultiAgentCharterSave(wsId).catch(showError);
    }, waitMs);
  }

  function triageRefresh() {
    return apiGet("triage_list", {})
      .then(function (response) {
        if (!response || !response.success) {
          throw new Error((response && response.error) || "Could not refresh triage");
        }
        state.triage = {
          count: String(response.count || "0"),
          cards: Array.isArray(response.cards) ? response.cards : []
        };
        state.openTriageSuppressProposalId = "";
        if (state.activeTriage && Number(state.triage.count || 0) < 1) {
          state.activeTriage = false;
        }
      });
  }

  function triageDecide(proposalId, decisionText) {
    var decision = trim(String(decisionText || ""));
    return apiPost("triage_decide", {
      proposal_id: String(proposalId || ""),
      decision: decision || "accepted"
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not apply decision");
      }
      state.triage.cards = Array.isArray(response.cards) ? response.cards : [];
      state.triage.count = String(state.triage.cards.length);
      state.openTriageSuppressProposalId = "";
    });
  }

  function triageSuppress(proposalId, scopeValue) {
    return apiPost("triage_suppress", {
      proposal_id: String(proposalId || ""),
      scope: scopeValue === "global" ? "global" : "workspace"
    }).then(function (response) {
      if (!response || !response.success) {
        throw new Error((response && response.error) || "Could not suppress proposal");
      }
      state.triage.cards = Array.isArray(response.cards) ? response.cards : [];
      state.triage.count = String(state.triage.cards.length);
      state.openTriageSuppressProposalId = "";
    });
  }

  function triageCleanup(directiveText) {
    return apiPost("triage_cleanup", {
      directive: String(directiveText || "")
    }).then(function (response) {
      if (!response || !response.success || !response.result) {
        throw new Error((response && response.error) || "Cleanup failed");
      }
      var result = response.result || {};
      var beforeCount = Number(result.before || 0);
      var afterCount = Number(result.after || 0);
      showTransientNotice("Triage cleanup preview: " + String(beforeCount) + " -> " + String(afterCount));
      return result;
    });
  }

  function openMultiAgentModal(workspaceId) {
    var wsId = trim(String(workspaceId || state.activeWorkspaceId || ""));
    if (!wsId) {
      return Promise.resolve(null);
    }
    state.commandRulesWorkspaceId = wsId;
    openModal(el.multi_agentModal);
    renderMultiAgentModal();
    return loadWorkspaceMultiAgent(wsId).catch(function () {
      return null;
    });
  }

  function multiAgentPreferredModelForResident(residentId, resident) {
    var explicit = trim(String(resident && resident.preferred_model || ""));
    if (explicit) {
      return explicit;
    }
    return "";
  }

  function isModelInstalled(modelName) {
    var target = trim(String(modelName || ""));
    if (!target) {
      return false;
    }
    for (var i = 0; i < state.models.length; i += 1) {
      if (String(state.models[i] || "") === target) {
        return true;
      }
    }
    return false;
  }

  function multiAgentSectionVisibilitySync() {
    if (el.multi_agentSectionAmendments && el.multi_agentToggleAmendments) {
      el.multi_agentSectionAmendments.classList.toggle("hidden", !el.multi_agentToggleAmendments.checked);
    }
    if (el.multi_agentSectionCommitments && el.multi_agentToggleCommitments) {
      el.multi_agentSectionCommitments.classList.toggle("hidden", !el.multi_agentToggleCommitments.checked);
    }
    if (el.multi_agentSectionPolicies && el.multi_agentTogglePolicies) {
      el.multi_agentSectionPolicies.classList.toggle("hidden", !el.multi_agentTogglePolicies.checked);
    }
  }

  function multiAgentParseEpoch(value) {
    var n = Number(value || 0);
    if (!isFinite(n) || n <= 0) {
      return 0;
    }
    return Math.floor(n);
  }

  function multiAgentRelativeAge(epochValue) {
    var epoch = multiAgentParseEpoch(epochValue);
    if (!epoch) {
      return "";
    }
    var nowEpoch = Math.floor(Date.now() / 1000);
    var delta = nowEpoch - epoch;
    if (!isFinite(delta) || delta < 0) {
      delta = 0;
    }
    if (delta < 60) {
      return "just now";
    }
    if (delta < 3600) {
      var mins = Math.floor(delta / 60);
      return String(mins) + "m ago";
    }
    if (delta < 86400) {
      var hours = Math.floor(delta / 3600);
      return String(hours) + "h ago";
    }
    var days = Math.floor(delta / 86400);
    if (days < 30) {
      return String(days) + "d ago";
    }
    var months = Math.floor(days / 30);
    if (months < 12) {
      return String(months) + "mo ago";
    }
    var years = Math.floor(months / 12);
    return String(years) + "y ago";
  }

  function multiAgentSortByCreatedDesc(items) {
    var list = Array.isArray(items) ? items.slice() : [];
    list.sort(function (a, b) {
      return multiAgentParseEpoch((b && b.created) || 0) - multiAgentParseEpoch((a && a.created) || 0);
    });
    return list;
  }

  function multiAgentCommitmentStatus(value) {
    var status = trim(String(value || "")).toLowerCase();
    if (status === "fulfilled" || status === "revoked") {
      return status;
    }
    return "active";
  }

  function multiAgentCommitmentStatusLabel(status) {
    if (status === "fulfilled") {
      return "Fulfilled";
    }
    if (status === "revoked") {
      return "Revoked";
    }
    return "Active";
  }

  function multiAgentSummaryLabel(baseText, count) {
    var total = Number(count || 0);
    if (!isFinite(total) || total < 1) {
      return String(baseText || "");
    }
    return String(baseText || "") + " (" + String(total) + ")";
  }

  function multiAgentHumanizeEnum(value) {
    var token = trim(String(value || ""));
    if (!token) {
      return "";
    }
    var spaced = token.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[_-]+/g, " ");
    return spaced.replace(/\s+/g, " ").replace(/^\w/, function (ch) {
      return ch.toUpperCase();
    });
  }

  function multiAgentTargetTypeLabel(value) {
    var token = trim(String(value || ""));
    if (token === "Resident") {
      return "Agent role";
    }
    if (token === "Charter") {
      return "Project instructions";
    }
    return multiAgentHumanizeEnum(token);
  }

  function multiAgentEscalationLabel(value) {
    return multiAgentHumanizeEnum(value);
  }

  function renderMultiAgentModal() {
    if (!el.multi_agentModal) {
      return;
    }
    var wsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
    var ws = wsId ? getWorkspaceById(wsId) : null;
    var data = wsId ? (state.workspaceMultiAgentById[wsId] || null) : null;
    var loading = !!state.workspaceMultiAgentLoadingById[wsId];
    var errorText = trim(String(state.workspaceMultiAgentErrorById[wsId] || ""));
    var catalog = Array.isArray(state.multi_agentCatalog && state.multi_agentCatalog.curated_residents)
      ? state.multi_agentCatalog.curated_residents
      : [];
    var residentMap = {};
    var activeResidents = Array.isArray(data && data.residents) ? data.residents : [];
    for (var r = 0; r < activeResidents.length; r += 1) {
      var activeResident = activeResidents[r] || {};
      var activeId = trim(String(activeResident.id || ""));
      if (!activeId) {
        continue;
      }
      residentMap[activeId] = activeResident;
    }

    if (el.multi_agentProjectLabel) {
      el.multi_agentProjectLabel.textContent = ws ? (ws.name || ws.id) : "No project selected";
    }
    if (el.multi_agentStatus) {
      if (loading) {
        el.multi_agentStatus.textContent = "Loading agent settings...";
      } else if (errorText) {
        el.multi_agentStatus.textContent = errorText;
      } else {
        el.multi_agentStatus.textContent = "";
      }
    }

    if (!data) {
      if (el.multi_agentResidentsList) {
        el.multi_agentResidentsList.innerHTML = "<p class='empty-state subtle-empty'>No agent settings loaded.</p>";
      }
      if (el.multi_agentPoliciesList) {
        el.multi_agentPoliciesList.innerHTML = "<p class='empty-state subtle-empty'>Decision filters created from suppress actions appear here.</p>";
      }
      if (el.multi_agentAmendmentsList) {
        el.multi_agentAmendmentsList.innerHTML = "<p class='empty-state subtle-empty'>No pending instruction updates.</p>";
      }
      if (el.multi_agentCommitmentsList) {
        el.multi_agentCommitmentsList.innerHTML = "<p class='empty-state subtle-empty'>No commitments logged.</p>";
      }
      if (el.multi_agentInterpretationList) {
        el.multi_agentInterpretationList.innerHTML = "<p class='empty-state subtle-empty'>No interpretation notes.</p>";
      }
      if (el.multi_agentRolesHint) {
        el.multi_agentRolesHint.textContent = "Turn built-in specialist agents on or off. Use each row menu for model and visibility.";
      }
      if (el.multi_agentAmendmentsSummary) {
        el.multi_agentAmendmentsSummary.textContent = "Instruction updates";
      }
      if (el.multi_agentInterpretationSummary) {
        el.multi_agentInterpretationSummary.textContent = "Interpretation notes";
      }
      if (el.multi_agentCommitmentsSummary) {
        el.multi_agentCommitmentsSummary.textContent = "Commitments";
      }
      if (el.multi_agentPoliciesSummary) {
        el.multi_agentPoliciesSummary.textContent = "Decision filters";
      }
      multiAgentSectionVisibilitySync();
      return;
    }

    if (el.multi_agentCharter) {
      el.multi_agentCharter.value = normalizeSharedInstructionsText(data.charter || "");
    }
    var toggles = data.toggles && typeof data.toggles === "object" ? data.toggles : {};
    if (el.multi_agentToggleAmendments) {
      el.multi_agentToggleAmendments.checked = !!Number(toggles.amendments || 0) || !!Number(toggles.interpretation_log || 0);
    }
    if (el.multi_agentToggleCommitments) {
      el.multi_agentToggleCommitments.checked = !!Number(toggles.commitments || 0);
    }
    if (el.multi_agentTogglePolicies) {
      el.multi_agentTogglePolicies.checked = !!Number(toggles.attention_policies || 0);
    }
    multiAgentSectionVisibilitySync();

    var amendments = multiAgentSortByCreatedDesc(Array.isArray(data.unratified_amendments) ? data.unratified_amendments : []);
    var commitments = multiAgentSortByCreatedDesc(Array.isArray(data.commitments_log) ? data.commitments_log : []);
    var interpretations = multiAgentSortByCreatedDesc(Array.isArray(data.interpretation_log) ? data.interpretation_log : []);
    var workspacePolicies = multiAgentSortByCreatedDesc(Array.isArray(data.attention_policies) ? data.attention_policies : []);
    var globalPolicies = multiAgentSortByCreatedDesc(Array.isArray(data.global_attention_policies) ? data.global_attention_policies : []);

    if (el.multi_agentAmendmentsSummary) {
      el.multi_agentAmendmentsSummary.textContent = multiAgentSummaryLabel("Instruction updates", amendments.length);
    }
    if (el.multi_agentInterpretationSummary) {
      el.multi_agentInterpretationSummary.textContent = multiAgentSummaryLabel("Interpretation notes", interpretations.length);
    }
    if (el.multi_agentCommitmentsSummary) {
      el.multi_agentCommitmentsSummary.textContent = multiAgentSummaryLabel("Commitments", commitments.length);
    }
    if (el.multi_agentPoliciesSummary) {
      el.multi_agentPoliciesSummary.textContent = multiAgentSummaryLabel("Decision filters", workspacePolicies.length + globalPolicies.length);
    }
    if (el.multi_agentRolesHint) {
      var activeRoleCount = 0;
      var visibleRoleCount = 0;
      for (var ar = 0; ar < activeResidents.length; ar += 1) {
        var roleEntry = activeResidents[ar] || {};
        if (roleEntry.enabled) {
          activeRoleCount += 1;
        }
        if (roleEntry.enabled && roleEntry.visible) {
          visibleRoleCount += 1;
        }
      }
      var roleTotal = catalog.length;
      if (roleTotal > 0) {
        el.multi_agentRolesHint.textContent = String(activeRoleCount) + " of " + String(roleTotal) + " active. " + String(visibleRoleCount) + " shown in Threads.";
      } else {
        el.multi_agentRolesHint.textContent = "Turn built-in specialist agents on or off. Use each row menu for model and visibility.";
      }
    }

    if (el.multi_agentResidentsList) {
      var residentsHtml = "";
      if (!catalog.length) {
        residentsHtml = "<p class='empty-state'>No built-in agent roles available.</p>";
      } else {
        var selectedResidentId = trim(String(state.multiAgentSelectedResidentIdByWorkspace[wsId] || ""));
        var openOptionsResidentId = trim(String(state.multiAgentOpenResidentOptionsByWorkspace[wsId] || ""));
        for (var cr = 0; cr < catalog.length; cr += 1) {
          var curated = catalog[cr] || {};
          var rid = trim(String(curated.id || ""));
          if (!rid) {
            continue;
          }
          var existing = residentMap[rid] || null;
          var isEnabled = !!(existing && existing.enabled);
          var showThreads = !!(existing && existing.visible);
          var selectedModel = trim(String(existing && existing.model || ""));
          var preferredModel = multiAgentPreferredModelForResident(rid, curated);
          var preferredInstalled = !preferredModel || isModelInstalled(preferredModel);
          var selectedInstalled = !selectedModel || isModelInstalled(selectedModel);
          var canEnable = preferredInstalled || !!selectedModel;
          var disableEnable = !canEnable;
          var selectedRow = selectedResidentId && selectedResidentId === rid;
          var roleStatusLabel = isEnabled ? "On" : "Off";
          var roleStatusClass = isEnabled ? "on" : "off";
          var roleModelLabel = selectedModel || "Auto";
          if (selectedModel && !selectedInstalled) {
            roleModelLabel += " (not installed)";
          }
          var optionsOpen = openOptionsResidentId && openOptionsResidentId === rid;

          residentsHtml += "<article class='resident-row" + (selectedRow ? " selected" : "") + "' data-action='multi_agent-resident-select' data-workspace-id='" + escAttr(wsId) + "' data-resident-id='" + escAttr(rid) + "'>";
          residentsHtml += "<div class='resident-row-head'>";
          residentsHtml += "<label class='resident-enable-row' title='Enable or disable this agent role.'>";
          residentsHtml += "<input type='checkbox' data-action='multi_agent-resident-enable' data-workspace-id='" + escAttr(wsId) + "' data-resident-id='" + escAttr(rid) + "'" + (isEnabled ? " checked" : "") + (disableEnable ? " disabled" : "") + " />";
          residentsHtml += "<span class='resident-title'>" + escHtml(curated.name || rid) + "</span>";
          residentsHtml += "</label>";
          residentsHtml += "<div class='resident-head-actions'>";
          residentsHtml += "<span class='resident-inline-chips'>";
          residentsHtml += "<span class='resident-chip status-" + escAttr(roleStatusClass) + "'>" + escHtml(roleStatusLabel) + "</span>";
          if (isEnabled) {
            residentsHtml += "<span class='resident-chip'>" + escHtml(roleModelLabel) + "</span>";
          }
          residentsHtml += "</span>";
          residentsHtml += "<button type='button' class='resident-menu-trigger' data-action='multi_agent-resident-options-toggle' data-resident-id='" + escAttr(rid) + "' title='Role options' aria-label='Role options'>&hellip;</button>";
          residentsHtml += "</div>";
          residentsHtml += "</div>";
          residentsHtml += "<p class='resident-description'>" + escHtml(curated.mandate || "") + "</p>";
          if (disableEnable) {
            residentsHtml += "<p class='resident-meta'>Preferred model missing. Choose an alternate model in options to enable this role.</p>";
          }
          residentsHtml += "<div class='resident-options" + (optionsOpen ? "" : " hidden") + "' id='multi_agent-resident-options-" + escAttr(rid) + "'>";
          residentsHtml += "<label class='toggle-row' title='When enabled, also show this agent in the threads list.'><input type='checkbox' data-action='multi_agent-resident-visible' data-workspace-id='" + escAttr(wsId) + "' data-resident-id='" + escAttr(rid) + "'" + (showThreads ? " checked" : "") + (isEnabled ? "" : " disabled") + " /> Show in threads list</label>";
          residentsHtml += "<label title='Override model selection for this agent role.'>Model override</label>";
          residentsHtml += "<select data-action='multi_agent-resident-model' data-workspace-id='" + escAttr(wsId) + "' data-resident-id='" + escAttr(rid) + "'>";
          residentsHtml += "<option value=''" + (!selectedModel ? " selected" : "") + ">Auto</option>";
          for (var mi = 0; mi < state.models.length; mi += 1) {
            var modelName = String(state.models[mi] || "");
            residentsHtml += "<option value='" + escAttr(modelName) + "'" + (selectedModel === modelName ? " selected" : "") + ">" + escHtml(modelName) + "</option>";
          }
          residentsHtml += "</select>";
          residentsHtml += "</div>";
          residentsHtml += "</article>";
        }
      }
      el.multi_agentResidentsList.innerHTML = residentsHtml;
    }

    if (el.multi_agentPoliciesList) {
      var policiesHtml = "";
      if (!workspacePolicies.length && !globalPolicies.length) {
        policiesHtml = "<p class='empty-state subtle-empty'>No decision filters yet. Use Suppress in Triage to create one.</p>";
      } else {
        for (var p = 0; p < workspacePolicies.length; p += 1) {
          var wp = workspacePolicies[p] || {};
          var wpId = trim(String(wp.id || ""));
          if (!wpId) {
            continue;
          }
          policiesHtml += "<article class='multi_agent-item multi-agent-card'>";
          policiesHtml += "<p class='multi-agent-card-title'>Project filter</p>";
          policiesHtml += "<div class='multi-agent-chip-row'>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(multiAgentEscalationLabel(wp.escalation_class) || "Any class") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(multiAgentTargetTypeLabel(wp.target_type) || "Any target") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(wp.resident || "Any agent") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>impact >= " + escHtml(String(wp.impact_threshold || "0")) + "</span>";
          policiesHtml += "</div>";
          var wpAge = multiAgentRelativeAge(wp.created);
          if (wpAge) {
            policiesHtml += "<p class='multi-agent-card-meta'>Created " + escHtml(wpAge) + "</p>";
          }
          policiesHtml += "<div class='multi-agent-card-actions'>";
          policiesHtml += "<button type='button' class='ghost' data-action='multi_agent-log-delete' data-workspace-id='" + escAttr(wsId) + "' data-log-kind='policies' data-entry-id='" + escAttr(wpId) + "'>Delete</button>";
          policiesHtml += "</div>";
          policiesHtml += "</article>";
        }
        for (var g = 0; g < globalPolicies.length; g += 1) {
          var gp = globalPolicies[g] || {};
          var gpId = trim(String(gp.id || ""));
          if (!gpId) {
            continue;
          }
          policiesHtml += "<article class='multi_agent-item multi-agent-card'>";
          policiesHtml += "<p class='multi-agent-card-title'>Global filter</p>";
          policiesHtml += "<div class='multi-agent-chip-row'>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(multiAgentEscalationLabel(gp.escalation_class) || "Any class") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(multiAgentTargetTypeLabel(gp.target_type) || "Any target") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>" + escHtml(gp.resident || "Any agent") + "</span>";
          policiesHtml += "<span class='multi-agent-chip'>impact >= " + escHtml(String(gp.impact_threshold || "0")) + "</span>";
          policiesHtml += "</div>";
          var gpAge = multiAgentRelativeAge(gp.created);
          if (gpAge) {
            policiesHtml += "<p class='multi-agent-card-meta'>Created " + escHtml(gpAge) + "</p>";
          }
          policiesHtml += "<div class='multi-agent-card-actions'>";
          policiesHtml += "<button type='button' class='ghost' data-action='multi_agent-log-delete' data-workspace-id='" + escAttr(wsId) + "' data-log-kind='global-policies' data-entry-id='" + escAttr(gpId) + "'>Delete</button>";
          policiesHtml += "</div>";
          policiesHtml += "</article>";
        }
      }
      el.multi_agentPoliciesList.innerHTML = policiesHtml;
    }

    if (el.multi_agentAmendmentsList) {
      var amendmentsHtml = "";
      if (!amendments.length) {
        amendmentsHtml = "<p class='empty-state subtle-empty'>No pending instruction updates.</p>";
      } else {
        for (var a = 0; a < amendments.length; a += 1) {
          var amendment = amendments[a] || {};
          var amendmentId = trim(String(amendment.id || ""));
          if (!amendmentId) {
            continue;
          }
          amendmentsHtml += "<article class='multi_agent-item multi-agent-card'>";
          amendmentsHtml += "<p class='multi-agent-card-title'>" + escHtml(amendment.summary || "Instruction update") + "</p>";
          if (trim(String(amendment.rationale || ""))) {
            amendmentsHtml += "<p class='multi-agent-card-body'>" + escHtml(amendment.rationale || "") + "</p>";
          }
          amendmentsHtml += "<div class='multi-agent-chip-row'>";
          amendmentsHtml += "<span class='multi-agent-chip'>" + escHtml(amendment.resident || "agent") + "</span>";
          amendmentsHtml += "<span class='multi-agent-chip'>" + escHtml(multiAgentEscalationLabel(amendment.escalation_class) || "Policy tradeoff") + "</span>";
          var amendmentAge = multiAgentRelativeAge(amendment.created);
          if (amendmentAge) {
            amendmentsHtml += "<span class='multi-agent-chip'>" + escHtml(amendmentAge) + "</span>";
          }
          amendmentsHtml += "</div>";
          amendmentsHtml += "<div class='multi-agent-card-actions'>";
          amendmentsHtml += "<button type='button' data-action='triage-decide' data-proposal-id='" + escAttr(amendmentId) + "'>Accept</button>";
          amendmentsHtml += "<button type='button' class='ghost' data-action='triage-decide' data-proposal-id='" + escAttr(amendmentId) + "' data-decision='dismissed'>Dismiss</button>";
          amendmentsHtml += "</div>";
          amendmentsHtml += "</article>";
        }
      }
      el.multi_agentAmendmentsList.innerHTML = amendmentsHtml;
    }

    if (el.multi_agentCommitmentsList) {
      var commitmentsHtml = "";
      if (!commitments.length) {
        commitmentsHtml = "<p class='empty-state subtle-empty'>No commitments logged.</p>";
      } else {
        for (var c = 0; c < commitments.length; c += 1) {
          var commitment = commitments[c] || {};
          var commitmentId = trim(String(commitment.id || ""));
          if (!commitmentId) {
            continue;
          }
          var commitmentStatus = multiAgentCommitmentStatus(commitment.status);
          commitmentsHtml += "<article class='multi_agent-item multi-agent-card'>";
          commitmentsHtml += "<p class='multi-agent-card-title'>" + escHtml(commitment.statement || "") + "</p>";
          commitmentsHtml += "<div class='multi-agent-chip-row'>";
          commitmentsHtml += "<span class='multi-agent-chip status-" + escAttr(commitmentStatus) + "'>" + escHtml(multiAgentCommitmentStatusLabel(commitmentStatus)) + "</span>";
          commitmentsHtml += "<span class='multi-agent-chip'>scope: " + escHtml(commitment.scope || "project") + "</span>";
          commitmentsHtml += "<span class='multi-agent-chip'>duration: " + escHtml(commitment.duration || "unspecified") + "</span>";
          commitmentsHtml += "<span class='multi-agent-chip'>revocability: " + escHtml(commitment.revocability || "revocable") + "</span>";
          commitmentsHtml += "<span class='multi-agent-chip'>audience: " + escHtml(commitment.audience || "internal") + "</span>";
          commitmentsHtml += "</div>";
          var commitmentAge = multiAgentRelativeAge(commitment.created);
          if (commitmentAge) {
            commitmentsHtml += "<p class='multi-agent-card-meta'>Created " + escHtml(commitmentAge) + "</p>";
          }
          commitmentsHtml += "<div class='multi-agent-card-actions'>";
          if (commitmentStatus === "active") {
            commitmentsHtml += "<button type='button' data-action='multi_agent-commitment-status' data-workspace-id='" + escAttr(wsId) + "' data-entry-id='" + escAttr(commitmentId) + "' data-status='fulfilled'>Fulfilled</button>";
            commitmentsHtml += "<button type='button' class='ghost' data-action='multi_agent-commitment-status' data-workspace-id='" + escAttr(wsId) + "' data-entry-id='" + escAttr(commitmentId) + "' data-status='revoked'>Revoke</button>";
          } else {
            commitmentsHtml += "<button type='button' data-action='multi_agent-commitment-status' data-workspace-id='" + escAttr(wsId) + "' data-entry-id='" + escAttr(commitmentId) + "' data-status='active'>Reopen</button>";
          }
          commitmentsHtml += "<button type='button' class='ghost' data-action='multi_agent-log-delete' data-workspace-id='" + escAttr(wsId) + "' data-log-kind='commitments' data-entry-id='" + escAttr(commitmentId) + "'>Delete</button>";
          commitmentsHtml += "</div>";
          commitmentsHtml += "</article>";
        }
      }
      el.multi_agentCommitmentsList.innerHTML = commitmentsHtml;
    }

    if (el.multi_agentInterpretationList) {
      var interpretationHtml = "";
      if (!interpretations.length) {
        interpretationHtml = "<p class='empty-state subtle-empty'>No interpretation notes.</p>";
      } else {
        for (var it = 0; it < interpretations.length; it += 1) {
          var entry = interpretations[it] || {};
          var interpretationId = trim(String(entry.id || ""));
          if (!interpretationId) {
            continue;
          }
          interpretationHtml += "<article class='multi_agent-item multi-agent-card'>";
          interpretationHtml += "<p class='multi-agent-card-body'>" + escHtml(entry.statement || "") + "</p>";
          var interpretationAge = multiAgentRelativeAge(entry.created);
          if (interpretationAge) {
            interpretationHtml += "<p class='multi-agent-card-meta'>Added " + escHtml(interpretationAge) + "</p>";
          }
          interpretationHtml += "<div class='multi-agent-card-actions'>";
          interpretationHtml += "<button type='button' class='ghost' data-action='multi_agent-log-delete' data-workspace-id='" + escAttr(wsId) + "' data-log-kind='interpretation' data-entry-id='" + escAttr(interpretationId) + "'>Delete</button>";
          interpretationHtml += "</div>";
          interpretationHtml += "</article>";
        }
      }
      el.multi_agentInterpretationList.innerHTML = interpretationHtml;
    }
  }

  function handleWorkspaceTreeClick(event) {
    var target = event.target.closest("[data-action]");
    if (!target) {
      return;
    }

    var action = target.getAttribute("data-action");
    var workspaceId = target.getAttribute("data-workspace-id");
    var conversationId = target.getAttribute("data-conversation-id");
    var proposalId = target.getAttribute("data-proposal-id");

    if (action === "select-triage") {
      state.activeTriage = true;
      state.activeWorkspaceId = "";
      state.activeConversationId = "";
      state.activeConversation = null;
      state.activeDraftWorkspaceId = "";
      renderUi();
      return;
    }

    if (action === "triage-open-context") {
      if (workspaceId && conversationId) {
        state.activeTriage = false;
        state.activeWorkspaceId = workspaceId;
        state.activeConversationId = conversationId;
        state.activeDraftWorkspaceId = "";
        loadConversation({
          workspaceId: workspaceId,
          conversationId: conversationId
        }).catch(showError);
        renderUi();
      }
      return;
    }

    if (action === "triage-decide") {
      if (!proposalId) {
        return;
      }
      var fixedDecision = trim(String(target.getAttribute("data-decision") || ""));
      var decisionAnswer = fixedDecision;
      if (!decisionAnswer) {
        decisionAnswer = window.prompt("Decision for this proposal", "accepted");
        if (decisionAnswer === null) {
          return;
        }
      }
      runWithControlPending(target, function () {
        return triageDecide(proposalId, decisionAnswer).then(function () {
          return loadState();
        }).then(renderUi);
      }).catch(showError);
      return;
    }

    if (action === "triage-suppress-open") {
      if (!proposalId) {
        return;
      }
      if (String(state.openTriageSuppressProposalId || "") === String(proposalId)) {
        state.openTriageSuppressProposalId = "";
      } else {
        state.openTriageSuppressProposalId = String(proposalId || "");
      }
      renderUi();
      return;
    }

    if (action === "triage-suppress-scope") {
      if (!proposalId) {
        return;
      }
      var scopePrompt = String(target.getAttribute("data-scope") || "") === "global" ? "global" : "workspace";
      state.openTriageSuppressProposalId = "";
      runWithControlPending(target, function () {
        return triageSuppress(proposalId, scopePrompt).then(function () {
          return loadState();
        }).then(renderUi);
      }).catch(showError);
      return;
    }

    if (action === "triage-cleanup" || action === "triage-cleanup-directed") {
      var directive = "";
      if (action === "triage-cleanup-directed") {
        var directivePrompt = window.prompt("Optional cleanup directive for Triage recompression", "Merge repeats and defer reversible low-impact items.");
        if (directivePrompt === null) {
          return;
        }
        directive = directivePrompt;
      }
      runWithControlPending(target, function () {
        return triageCleanup(directive).then(function (result) {
          var collapsed = Array.isArray(result && result.collapsed) ? result.collapsed : [];
          if (collapsed.length) {
            var lines = [];
            for (var i = 0; i < collapsed.length && i < 6; i += 1) {
              lines.push("- " + String(collapsed[i].summary || "Decision cluster") + " (" + String(collapsed[i].count || 0) + ")");
            }
            window.alert("Cleanup preview:\n" + lines.join("\n"));
          }
          return triageRefresh();
        }).then(renderUi);
      }).catch(showError);
      return;
    }

    if (action === "toggle-workspace") {
      if (workspaceId) {
        state.expandedWorkspaceIds[workspaceId] = !state.expandedWorkspaceIds[workspaceId];
        renderUi();
      }
      return;
    }

    if (action === "toggle-workspace-menu") {
      event.preventDefault();
      event.stopPropagation();
      if (state.openWorkspaceMenuWorkspaceId === workspaceId) {
        state.openWorkspaceMenuWorkspaceId = "";
      } else {
        state.openWorkspaceMenuWorkspaceId = workspaceId || "";
      }
      renderUi();
      return;
    }

    if (action === "new-conversation") {
      if (workspaceId) {
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        runWithControlPending(target, function () {
          return createDraftForWorkspace(workspaceId);
        }).catch(showError);
      }
      return;
    }

    if (action === "open-workspace-multi_agent") {
      if (!workspaceId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      state.openWorkspaceMenuWorkspaceId = "";
      openMultiAgentModal(workspaceId).catch(showError);
      return;
    }

    if (action === "rename-workspace") {
      if (!workspaceId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      var workspaceToRename = getWorkspaceById(workspaceId);
      var currentName = workspaceToRename && workspaceToRename.name ? workspaceToRename.name : "";
      var nextName = window.prompt("Rename project", currentName);
      if (nextName === null) {
        return;
      }
      runWithControlPending(target, function () {
        return renameWorkspace(workspaceId, nextName);
      }).catch(showError);
      return;
    }

    if (action === "open-workspace-approvals") {
      if (!workspaceId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      state.commandRulesWorkspaceId = workspaceId;
      state.openWorkspaceMenuWorkspaceId = "";
      openSettingsModal().then(function () {
        return loadCommandRules(workspaceId);
      }).catch(showError);
      return;
    }

    if (action === "remove-workspace") {
      if (!workspaceId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      var workspace = getWorkspaceById(workspaceId);
      var label = workspace && workspace.name ? workspace.name : "this project";
      if (!window.confirm("Remove " + label + " and its Artificer thread history?")) {
        return;
      }
      runWithControlPending(target, function () {
        return removeWorkspace(workspaceId);
      }).catch(showError);
      return;
    }

    if (action === "arm-archive-conversation") {
      if (!workspaceId || !conversationId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      var archiveKey = conversationReadKey(workspaceId, conversationId);
      state.pendingArchiveKey = archiveKey;
      state.pendingArchiveReadyAt = Date.now() + 250;
      renderUi();
      markArchiveConfirmReady(workspaceId, conversationId, archiveKey);
      return;
    }

    if (action === "confirm-archive-conversation") {
      if (!workspaceId || !conversationId) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      var key = conversationReadKey(workspaceId, conversationId);
      if (key !== state.pendingArchiveKey || key === state.pendingArchiveSubmittingKey || Date.now() < Number(state.pendingArchiveReadyAt || 0)) {
        return;
      }
      state.pendingArchiveSubmittingKey = key;
      renderUi();
      archiveConversation(workspaceId, conversationId).catch(function (error) {
        state.pendingArchiveSubmittingKey = "";
        renderUi();
        showError(error);
      });
      return;
    }

    if (action === "select-workspace") {
      if (workspaceId) {
        state.activeTriage = false;
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        state.expandedWorkspaceIds[workspaceId] = !state.expandedWorkspaceIds[workspaceId];
        renderUi();
      }
      return;
    }

    if (action === "select-conversation") {
      if (workspaceId && conversationId) {
        state.activeTriage = false;
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        runWithControlPending(target, function () {
          return selectConversation(workspaceId, conversationId);
        }, { spinner: false }).catch(showError);
      }
      return;
    }

    if (action === "select-draft") {
      if (workspaceId) {
        state.activeTriage = false;
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        runWithControlPending(target, function () {
          return selectDraft(workspaceId);
        }, { spinner: false }).catch(showError);
      }
    }
  }

  function handleWorkspaceTreeKeydown(event) {
    var target = event.target.closest(".conversation-row[role='button']");
    if (!target) {
      return;
    }
    if (event.key !== "Enter" && event.key !== " ") {
      return;
    }
    event.preventDefault();
    target.click();
  }

  function handleAttachmentStripClick(event) {
    var target = event.target.closest("[data-action]");
    if (!target) {
      return;
    }

    var action = target.getAttribute("data-action");
    var attachmentId = target.getAttribute("data-attachment-id");
    if (!attachmentId) {
      return;
    }

    if (action === "remove-attachment") {
      event.preventDefault();
      event.stopPropagation();
      removePendingAttachmentById(attachmentId);
      return;
    }

    if (action === "preview-attachment") {
      openAttachmentPreview(attachmentId);
    }
  }

  function handleAttachmentStripKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") {
      return;
    }
    var target = event.target.closest("[data-action='preview-attachment']");
    if (!target) {
      return;
    }
    var attachmentId = target.getAttribute("data-attachment-id");
    if (!attachmentId) {
      return;
    }
    event.preventDefault();
    openAttachmentPreview(attachmentId);
  }

  function onWorkspaceBrowseClick() {
    if (state.pickingWorkspace) {
      return Promise.resolve();
    }
    state.pickingWorkspace = true;
    state.awaitingDirPicker = false;
    return apiGet("pick_workspace")
      .then(function (picked) {
        if (picked.success && picked.cancelled) {
          return;
        }

        if (picked.success && picked.path) {
          el.workspacePath.value = picked.path;
          return;
        }

        if (el.workspaceDirPicker) {
          state.awaitingDirPicker = true;
          el.workspaceDirPicker.value = "";
          el.workspaceDirPicker.click();
          return;
        }

        throw new Error(picked.error || "Could not open folder picker.");
      })
      .finally(function () {
        if (!state.awaitingDirPicker) {
          state.pickingWorkspace = false;
        }
      });
  }

  function onWorkspaceDirPicked(event) {
    var input = event.target;
    if (!input || !input.files || input.files.length === 0) {
      state.awaitingDirPicker = false;
      state.pickingWorkspace = false;
      return Promise.resolve();
    }

    var firstFile = input.files[0];
    var pickedPath = "";

    if (firstFile.path) {
      pickedPath = dirname(firstFile.path);
    }

    if (!pickedPath) {
      state.awaitingDirPicker = false;
      state.pickingWorkspace = false;
      return Promise.reject(new Error("Folder path unavailable in this browser. Use Browse."));
    }

    el.workspacePath.value = pickedPath;
    state.awaitingDirPicker = false;
    state.pickingWorkspace = false;
    return Promise.resolve();
  }

  function onWorkspaceModalSubmit(event) {
    event.preventDefault();
    var path = trim(el.workspacePath.value);
    var name = trim(el.workspaceName.value);
    if (!path) {
      return Promise.reject(new Error("Project path is required."));
    }

    return addWorkspaceByPath(path, name).then(function () {
      el.workspacePath.value = "";
      el.workspaceName.value = "";
      closeModal(el.workspaceModal);
      return refreshAll();
    });
  }

  function onWorkspaceDropped(event) {
    event.preventDefault();
    setWorkspaceDropActive(false);
    var droppedPath = extractPathFromDataTransfer(event.dataTransfer);
    if (trim(droppedPath)) {
      return addWorkspaceFromDropCandidate(droppedPath).then(function () {
        return refreshAll();
      });
    }

    el.workspacePath.value = "";
    el.workspaceName.value = "";
    openModal(el.workspaceModal);
    return onWorkspaceBrowseClick().then(function () {
      var pickedPath = trim(el.workspacePath.value);
      if (!pickedPath) {
        closeModal(el.workspaceModal);
        return null;
      }
      return addWorkspaceByPath(pickedPath, trim(el.workspaceName.value)).then(function () {
        el.workspacePath.value = "";
        el.workspaceName.value = "";
        closeModal(el.workspaceModal);
        return refreshAll();
      });
    });
  }

  function onComposerDragEnter(event) {
    event.preventDefault();
    state.composerDragDepth += 1;
    setComposerDragActive(true);
  }

  function onComposerDragOver(event) {
    event.preventDefault();
    setComposerDragActive(true);
  }

  function onComposerDragLeave(event) {
    event.preventDefault();
    state.composerDragDepth = Math.max(0, state.composerDragDepth - 1);
    if (state.composerDragDepth === 0) {
      setComposerDragActive(false);
    }
  }

  function onComposerDropped(event) {
    event.preventDefault();
    state.composerDragDepth = 0;
    setComposerDragActive(false);
    var files = event.dataTransfer && event.dataTransfer.files ? event.dataTransfer.files : [];
    addComposerFiles(files);
  }

  function onAttachmentPickerChange(event) {
    var input = event.target;
    var files = input && input.files ? input.files : [];
    addComposerFiles(files);
    if (input) {
      input.value = "";
    }
  }

  function onPromptPaste(event) {
    var clipboard = event.clipboardData;
    if (!clipboard || !clipboard.files || clipboard.files.length < 1) {
      return;
    }
    event.preventDefault();
    addComposerFiles(clipboard.files);
  }

  function onRunSubmit(event) {
    event.preventDefault();

    var rawPrompt = String(el.runPrompt.value || "");
    var directive = parsePromptModeDirective(rawPrompt);
    if (directive.mode) {
      saveRunMode(directive.mode);
      showTransientNotice("Run mode: " + runModeLabel(directive.mode));
    }
    var prompt = trim(directive.prompt || rawPrompt);
    var queuedRunMode = normalizeRunMode(directive.mode || state.runMode);
    var queuedAssistantMode = queuedRunMode === "assistant" ? normalizeAssistantModeId(state.assistantModeId) : "";
    var queuedComputeBudget = normalizeComputeBudget(state.computeBudget);
    var queuedExplicitSkillIds = Array.isArray(directive.skillIds) ? directive.skillIds : [];
    if (queuedExplicitSkillIds.length) {
      showTransientNotice("Skills: " + queuedExplicitSkillIds.join(", "));
    }
    if (!prompt) {
      if (directive.mode) {
        el.runPrompt.value = "";
        if (state.activeDraftWorkspaceId) {
          state.draftTextByWorkspace[state.activeDraftWorkspaceId] = "";
        }
        clearDraftAutosaveTimer();
        renderUi();
      }
      return;
    }

    if (!state.activeWorkspaceId && state.activeConversationId) {
      var resolvedWorkspaceId = findWorkspaceIdForConversation(state.activeConversationId);
      if (resolvedWorkspaceId) {
        state.activeWorkspaceId = resolvedWorkspaceId;
      }
    }

    if (!state.activeConversationId && !state.activeDraftWorkspaceId && state.activeWorkspaceId) {
      state.activeDraftWorkspaceId = state.activeWorkspaceId;
    }

    var queuedPrompt = directive.mode ? trim(rawPrompt) : prompt;
    var pendingKey = activeOutgoingKey();
    var pendingId = addPendingOutgoing(pendingKey, queuedPrompt);
    el.runPrompt.value = "";
    if (state.activeDraftWorkspaceId) {
      state.draftTextByWorkspace[state.activeDraftWorkspaceId] = "";
    }
    renderUi();

    clearDraftAutosaveTimer();

    ensureConversationFromDraft(queuedPrompt)
      .then(function (conversationId) {
        var workspaceId = state.activeWorkspaceId;
        if (!workspaceId || !conversationId) {
          throw new Error("Choose a project thread first.");
        }
        var conversationKey = outgoingKeyFor(workspaceId, conversationId, "");
        movePendingOutgoing(pendingKey, conversationKey, pendingId);
        pendingKey = conversationKey;
        return uploadPendingAttachments(workspaceId, conversationId).then(function (uploadedAttachments) {
          var attachmentIds = [];
          for (var i = 0; i < uploadedAttachments.length; i += 1) {
            if (uploadedAttachments[i] && uploadedAttachments[i].id) {
              attachmentIds.push(String(uploadedAttachments[i].id));
            }
          }
          return enqueuePrompt(
            workspaceId,
            conversationId,
            queuedPrompt,
            "tail",
            attachmentIds,
            queuedRunMode,
            queuedAssistantMode,
            queuedComputeBudget,
            queuedExplicitSkillIds,
            state.permissionMode,
            state.commandExecMode
          ).then(function () {
            resetComposerAttachments();
          });
        }).then(function () {
          state.activeWorkspaceId = workspaceId;
          state.activeConversationId = conversationId;
          state.activeDraftWorkspaceId = "";
          syncSelectionUrl(false);
          return loadConversation().catch(function () {
            return null;
          });
        });
      })
      .then(function () {
        renderUi();
        kickQueueWorker();
      })
      .catch(function (err) {
        removePendingOutgoing(pendingKey, pendingId);
        el.runPrompt.value = queuedPrompt;
        showError(err);
      })
      .finally(function () {
        renderUi();
      });
  }

  function onCommitContinue() {
    if (!state.activeWorkspaceId) {
      return Promise.reject(new Error("Select a project first."));
    }

    var includeUnstaged = el.commitIncludeUnstaged.checked ? "1" : "0";
    var message = el.commitMessage.value;
    var nextStep = el.commitNextStep.value === "commit-push" ? "1" : "0";

    return apiPost("git_commit", {
      workspace_id: state.activeWorkspaceId,
      include_unstaged: includeUnstaged,
      message: message,
      push: nextStep
    })
      .then(function (response) {
        if (!response.success) {
          throw new Error(response.error || "Commit failed");
        }
        appendTerminalLine(response.output || "Commit complete.");
        closeModal(el.commitModal);
        return refreshGitStatus();
      })
      .then(function () {
        return refreshBranches().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (state.diffOpen) {
          return refreshDiff().catch(function () {
            return null;
          });
        }
        return null;
      })
      .then(function () {
        renderUi();
      });
  }

  function openDiffPanel() {
    state.diffOpen = true;
    return refreshDiff().then(function () {
      renderUi();
    });
  }

  function closeDiffPanel() {
    state.diffOpen = false;
    renderUi();
    return Promise.resolve();
  }

  function toggleDiffPanel() {
    if (state.diffOpen) {
      return closeDiffPanel();
    } else {
      return openDiffPanel();
    }
  }

  function openTerminal() {
    state.terminalOpen = true;
    if (state.activeWorkspaceId) {
      var ws = getWorkspaceById(state.activeWorkspaceId);
      state.terminalCwd = ws ? ws.path : "";
    }
    renderUi();
    ensureTerminalSession().then(function () {
      return pollTerminalSessionOnce();
    }).catch(showError);
    setTimeout(function () {
      if (el.terminalOutput) {
        el.terminalOutput.focus();
      }
    }, 0);
  }

  function closeTerminal() {
    var wsId = String(state.terminalSessionWorkspaceId || state.activeWorkspaceId || "");
    var sessionId = String(state.terminalSessionId || "");
    stopTerminalPolling();
    if (wsId && sessionId) {
      apiPost("terminal_session_stop", {
        workspace_id: wsId,
        session_id: sessionId
      }, { timeoutMs: 5000 }).catch(function () {
        return null;
      });
    }
    state.terminalOpen = false;
    state.terminalSessionId = "";
    state.terminalSessionWorkspaceId = "";
    state.terminalStreamText = "";
    state.terminalStreamOffset = 0;
    state.terminalInputBuffer = "";
    renderUi();
  }

  function toggleTerminal() {
    if (state.terminalOpen) {
      closeTerminal();
    } else {
      openTerminal();
    }
  }

  function bindEvents() {
    function on(node, eventName, handler) {
      if (!node || typeof node.addEventListener !== "function") {
        return;
      }
      node.addEventListener(eventName, handler);
    }

    if (el.attachmentPicker) {
      el.attachmentPicker.setAttribute("accept", attachmentAcceptValue);
    }

    on(el.workspaceTree, "click", function (event) {
      handleWorkspaceTreeClick(event);
    });
    on(el.workspaceTree, "keydown", function (event) {
      handleWorkspaceTreeKeydown(event);
    });

    on(el.addWorkspaceBtn, "click", function () {
      openModal(el.workspaceModal);
      setTimeout(function () {
        el.workspaceBrowseBtn.focus();
      }, 0);
    });

    on(el.organizeBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("organize-menu", el.organizeBtn);
    });

    on(el.organizeMenu, "click", function (event) {
      var button = event.target.closest("button[data-organize-mode], button[data-organize-sort], button[data-organize-show]");
      if (!button) {
        return;
      }
      var modeValue = button.getAttribute("data-organize-mode");
      var sortValue = button.getAttribute("data-organize-sort");
      var showValue = button.getAttribute("data-organize-show");
      if (modeValue) {
        saveOrganizeMode(modeValue);
      } else if (sortValue) {
        saveSortMode(sortValue);
      } else if (showValue) {
        saveOrganizeShow(showValue);
      }
      closeAllMenus();
      renderUi();
    });

    on(el.modelStatusBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("models-pane", el.modelStatusBtn);
      if (!el.modelsPane || el.modelsPane.classList.contains("hidden")) {
        return;
      }
      runWithControlPending(el.modelStatusBtn, function () {
        return refreshModelData({ force: true, silent: false })
          .then(function () {
            return null;
          })
          .catch(function () {
            renderUi();
          });
      }, { spinner: false }).catch(function () {
        return null;
      });
    });

    on(el.themePickerBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("theme-picker-menu", el.themePickerBtn);
    });

    on(el.themePickerBtn, "keydown", function (event) {
      if (event.key !== "ArrowUp" && event.key !== "ArrowDown") {
        return;
      }
      event.preventDefault();
      closeAllMenus();
      cycleTheme(event.key === "ArrowUp" ? -1 : 1);
    });

    on(el.themePickerList, "click", function (event) {
      var button = event.target.closest("button[data-theme-name]");
      if (!button) {
        return;
      }
      var themeName = button.getAttribute("data-theme-name");
      applyTheme(themeName);
      closeAllMenus();
      renderThemePicker();
      if (el.themePickerBtn) {
        el.themePickerBtn.focus();
      }
    });

    on(el.modelsBoxList, "click", function (event) {
      var installBtn = event.target.closest("button[data-action='install-model'][data-model-name]");
      if (installBtn) {
        var installModel = installBtn.getAttribute("data-model-name");
        runWithControlPending(installBtn, function () {
          return startModelInstall(installModel);
        }).catch(showError);
        return;
      }
      var button = event.target.closest("button[data-model-name]");
      if (!button) {
        return;
      }
      var modelName = button.getAttribute("data-model-name");
      runWithControlPending(button, function () {
        return applyModelSelection(modelName).then(function () {
          closeAllMenus();
          renderUi();
        });
      }).catch(showError);
    });

    on(el.modelPickerBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("model-picker-menu", el.modelPickerBtn);
    });

    on(el.modelPickerList, "click", function (event) {
      var button = event.target.closest("button[data-model-name]");
      if (!button) {
        return;
      }
      var modelName = button.getAttribute("data-model-name");
      runWithControlPending(button, function () {
        return applyModelSelection(modelName)
          .then(function () {
            closeAllMenus();
            renderUi();
          });
      }).catch(showError);
    });

    on(el.runModeBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("run-mode-menu", el.runModeBtn);
    });

    on(el.runModeMenu, "click", function (event) {
      var moreToggle = event.target.closest("button[data-action='run-mode-more-toggle']");
      if (moreToggle) {
        state.runModeMoreExpanded = !state.runModeMoreExpanded;
        renderUi();
        return;
      }
      var assistantModeItem = event.target.closest("button[data-assistant-mode-id]");
      if (assistantModeItem) {
        saveRunMode("assistant");
        saveAssistantModeId(assistantModeItem.getAttribute("data-assistant-mode-id") || "");
        state.runModeMoreExpanded = false;
        closeAllMenus();
        renderUi();
        return;
      }
      var item = event.target.closest("button[data-run-mode]");
      if (!item) {
        return;
      }
      saveRunMode(item.getAttribute("data-run-mode"));
      if (normalizeRunMode(item.getAttribute("data-run-mode")) !== "assistant") {
        state.runModeMoreExpanded = false;
      }
      closeAllMenus();
      renderUi();
    });

    on(el.agentLoopToggle, "click", function () {
      saveAgentLoopEnabled(!state.agentLoopEnabled);
      renderUi();
    });

    on(el.reasoningMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("reasoning-menu", el.reasoningMenuBtn);
    });

    on(el.reasoningMenu, "click", function (event) {
      var item = event.target.closest("button[data-reasoning]");
      if (!item) {
        return;
      }
      saveReasoningEffort(item.getAttribute("data-reasoning"));
      closeAllMenus();
      renderUi();
    });

    on(el.computeMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("compute-menu", el.computeMenuBtn);
    });

    on(el.computeMenu, "click", function (event) {
      var item = event.target.closest("button[data-compute-budget]");
      if (!item) {
        return;
      }
      saveComputeBudget(item.getAttribute("data-compute-budget"));
      closeAllMenus();
      renderUi();
    });

    on(el.workspaceModalClose, "click", function () {
      closeModal(el.workspaceModal);
    });

    on(el.workspaceCancelBtn, "click", function () {
      closeModal(el.workspaceModal);
    });

    on(el.workspaceModal, "click", function (event) {
      if (event.target === el.workspaceModal && !state.pickingWorkspace) {
        closeModal(el.workspaceModal);
      }
    });

    on(el.workspaceForm, "submit", function (event) {
      var submitter = event.submitter || (el.workspaceForm && el.workspaceForm.querySelector("button[type='submit']"));
      runWithControlPending(submitter, function () {
        return onWorkspaceModalSubmit(event);
      }).catch(showError);
    });

    on(el.workspaceBrowseBtn, "click", function () {
      runWithControlPending(el.workspaceBrowseBtn, function () {
        return onWorkspaceBrowseClick();
      }).catch(showError);
    });

    on(el.workspaceDirPicker, "change", function (event) {
      onWorkspaceDirPicked(event).catch(showError);
    });

    window.addEventListener("focus", function () {
      if (state.awaitingDirPicker) {
        window.setTimeout(function () {
          if (!state.awaitingDirPicker) {
            return;
          }
          state.awaitingDirPicker = false;
          state.pickingWorkspace = false;
        }, 0);
      }
      if (state.initialLoadComplete) {
        refreshModelData({ force: true, silent: true }).then(function (updated) {
          if (updated) {
            renderUi();
          }
        }).catch(function () {
          return null;
        });
      }
    });

    window.addEventListener("popstate", function () {
      navigateToRouteSelection().catch(showError);
    });

    window.addEventListener("mousemove", function (event) {
      onPaneDragMove(event);
    });

    window.addEventListener("mouseup", function () {
      stopPaneDrag();
    });

    window.addEventListener("blur", function () {
      stopPaneDrag();
    });

    window.addEventListener("resize", function () {
      applyPaneWidths();
      updateToolbarCompaction();
    });

    document.addEventListener("mouseover", function (event) {
      var target = event.target.closest("[data-tooltip]");
      if (!target) {
        hideTooltip();
        return;
      }
      scheduleTooltipFor(target);
    });

    document.addEventListener("focusin", function (event) {
      var target = event.target.closest("[data-tooltip]");
      if (!target) {
        hideTooltip();
        return;
      }
      scheduleTooltipFor(target);
    });

    document.addEventListener("mousemove", function (event) {
      if (!tooltipTarget || !tooltipEl || tooltipEl.getAttribute("aria-hidden") === "true") {
        return;
      }
      positionTooltip(tooltipTarget);
      if (!tooltipTarget.contains(event.target) && event.target !== tooltipTarget) {
        hideTooltip();
      }
    });

    document.addEventListener("mouseout", function (event) {
      if (!tooltipTarget) {
        return;
      }
      if (tooltipTarget.contains(event.relatedTarget)) {
        return;
      }
      hideTooltip();
    });

    document.addEventListener("focusout", function (event) {
      if (!tooltipTarget) {
        return;
      }
      if (tooltipTarget.contains(event.relatedTarget)) {
        return;
      }
      hideTooltip();
    });

    on(el.workspacePanel, "dragenter", function (event) {
      event.preventDefault();
      setWorkspaceDropActive(true);
    });

    on(el.workspacePanel, "dragover", function (event) {
      event.preventDefault();
      setWorkspaceDropActive(true);
    });

    on(el.workspacePanel, "dragleave", function (event) {
      if (!el.workspacePanel.contains(event.relatedTarget)) {
        setWorkspaceDropActive(false);
      }
    });

    on(el.workspacePanel, "drop", function (event) {
      runWithControlPending(el.workspacePanel, function () {
        return onWorkspaceDropped(event);
      }, { spinner: false }).catch(showError);
    });

    if (el.threadsResizer) {
      on(el.threadsResizer, "mousedown", function (event) {
        startPaneDrag("threads", event);
      });
    }

    if (el.diffResizer) {
      on(el.diffResizer, "mousedown", function (event) {
        startPaneDrag("diff", event);
      });
    }

    if (el.modelsPaneResizer) {
      on(el.modelsPaneResizer, "mousedown", function (event) {
        if (!el.modelsPane || el.modelsPane.classList.contains("hidden")) {
          return;
        }
        startPaneDrag("models", event);
      });
    }

    on(el.openMainBtn, "click", function () {
      runWithControlPending(el.openMainBtn, function () {
        return performOpenTarget(state.lastOpenTarget);
      }).catch(showError);
    });

    if (el.workspacePathWidget) {
      on(el.workspacePathWidget, "click", function (event) {
        var ws = activeWorkspace();
        if (!ws || !ws.path) {
          return;
        }
        if (event && Number(event.detail || 0) >= 2) {
          if (pathWidgetClickTimer) {
            clearTimeout(pathWidgetClickTimer);
            pathWidgetClickTimer = null;
          }
          runWithControlPending(el.workspacePathWidget, function () {
            return performOpenTarget("finder");
          }, { spinner: false }).catch(showError);
          return;
        }
        if (pathWidgetClickTimer) {
          clearTimeout(pathWidgetClickTimer);
          pathWidgetClickTimer = null;
        }
        pathWidgetClickTimer = setTimeout(function () {
          pathWidgetClickTimer = null;
          copyTextToClipboard(ws.path).then(function (ok) {
            if (!ok) {
              throw new Error("Could not copy path.");
            }
            showTransientNotice("Path copied");
          }).catch(function (error) {
            showError(error);
          });
        }, 220);
      });

      on(el.workspacePathWidget, "dblclick", function (event) {
        event.preventDefault();
        if (pathWidgetClickTimer) {
          clearTimeout(pathWidgetClickTimer);
          pathWidgetClickTimer = null;
        }
        runWithControlPending(el.workspacePathWidget, function () {
          return performOpenTarget("finder");
        }, { spinner: false }).catch(showError);
      });
    }

    on(el.openMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("open-menu", el.openMenuBtn);
    });

    on(el.openMenu, "click", function (event) {
      var item = event.target.closest("button[data-open-target]");
      if (!item || !state.activeWorkspaceId) {
        return;
      }
      var target = item.getAttribute("data-open-target");
      runWithControlPending(item, function () {
        return performOpenTarget(target);
      }).catch(showError);
    });

    on(el.branchMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (!state.activeWorkspaceId) {
        return;
      }
      var gitState = activeGitState();
      if (!gitState.is_repo) {
        runWithControlPending(el.branchMenuBtn, function () {
          return createRepoForActiveWorkspace();
        }).catch(showError);
        return;
      }
      runWithControlPending(el.branchMenuBtn, function () {
        return refreshBranches().finally(function () {
          renderBranchMenu();
          toggleMenu("branch-menu", el.branchMenuBtn);
        });
      }, { spinner: false }).catch(showError);
    });

    on(el.branchMenuList, "click", function (event) {
      var actionItem = event.target.closest("button[data-branch-action]");
      if (actionItem) {
        var branchAction = actionItem.getAttribute("data-branch-action");
        if (branchAction === "create-repo") {
          runWithControlPending(actionItem, function () {
            return createRepoForActiveWorkspace();
          })
            .then(function () {
              closeAllMenus();
            })
            .catch(showError);
        }
        return;
      }

      var item = event.target.closest("button[data-branch-select]");
      if (!item || !state.activeWorkspaceId) {
        return;
      }
      var branch = item.getAttribute("data-branch-select");
      runWithControlPending(item, function () {
        return apiPost("git_checkout_branch", {
          workspace_id: state.activeWorkspaceId,
          branch: branch,
          create: "0"
        })
          .then(function (response) {
            if (!response.success) {
              throw new Error(response.error || "Branch checkout failed");
            }
            appendTerminalLine(response.output || ("Checked out " + branch));
            return refreshGitStatus();
          })
          .then(function () {
            return refreshBranches();
          })
          .then(function () {
            closeAllMenus();
            renderUi();
          });
      }).catch(showError);
    });

    on(el.branchCreateForm, "submit", function (event) {
      event.preventDefault();
      if (!state.activeWorkspaceId) {
        return;
      }
      var branchName = trim(el.branchCreateInput.value);
      if (!branchName) {
        return;
      }
      var submitter = event.submitter || el.branchCreateSubmit;
      runWithControlPending(submitter, function () {
        return apiPost("git_checkout_branch", {
          workspace_id: state.activeWorkspaceId,
          branch: branchName,
          create: "1"
        })
          .then(function (response) {
            if (!response.success) {
              throw new Error(response.error || "Branch create failed");
            }
            appendTerminalLine(response.output || ("Created branch " + branchName));
            el.branchCreateInput.value = "";
            if (el.branchCreateSubmit) {
              el.branchCreateSubmit.disabled = true;
            }
            return refreshGitStatus();
          })
          .then(function () {
            return refreshBranches();
          })
          .then(function () {
            closeAllMenus();
            renderUi();
          });
      }).catch(showError);
    });

    on(el.branchCreateInput, "input", function () {
      if (!el.branchCreateSubmit) {
        return;
      }
      el.branchCreateSubmit.disabled = trim(el.branchCreateInput.value) === "";
    });

    on(el.commitMainBtn, "click", function () {
      runWithControlPending(el.commitMainBtn, function () {
        return performCommitAction(state.lastCommitAction);
      }, { spinner: false }).catch(showError);
    });

    on(el.commitMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("commit-menu", el.commitMenuBtn);
    });

    on(el.commitMenu, "click", function (event) {
      var item = event.target.closest("button[data-commit-action]");
      if (!item) {
        return;
      }
      var action = item.getAttribute("data-commit-action");
      runWithControlPending(item, function () {
        return performCommitAction(action);
      }, { spinner: false }).catch(showError);
    });

    on(el.commitModalClose, "click", function () {
      closeModal(el.commitModal);
    });

    on(el.commitModal, "click", function (event) {
      if (event.target === el.commitModal) {
        closeModal(el.commitModal);
      }
    });

    on(el.commitContinueBtn, "click", function () {
      runWithControlPending(el.commitContinueBtn, function () {
        return onCommitContinue();
      }).catch(showError);
    });

    on(el.permissionsMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleMenu("permissions-menu", el.permissionsMenuBtn);
    });

    on(el.permissionsMenu, "click", function (event) {
      var commandItem = event.target.closest("button[data-command-exec]");
      if (commandItem) {
        var commandMode = commandItem.getAttribute("data-command-exec");
        runWithControlPending(commandItem, function () {
          return setCommandExecMode(commandMode)
            .then(function () {
              closeAllMenus();
              renderUi();
            });
        }).catch(showError);
        return;
      }

      var item = event.target.closest("button[data-permission]");
      if (!item) {
        return;
      }
      var permission = item.getAttribute("data-permission");
      savePermissionMode(permission);
      closeAllMenus();
      renderUi();
    });

    if (el.networkToggleBtn) {
      on(el.networkToggleBtn, "click", function (event) {
        event.preventDefault();
        var enabled = !state.networkAccess;
        saveNetworkAccess(enabled);
        if (!enabled) {
          saveWebAccess(false);
        }
        renderUi();
      });
    }

    if (el.webToggleBtn) {
      on(el.webToggleBtn, "click", function (event) {
        event.preventDefault();
        if (!state.networkAccess) {
          saveNetworkAccess(true);
        }
        saveWebAccess(!state.webAccess);
        renderUi();
      });
    }

    on(el.runActionBtn, "click", function () {
      openModal(el.runActionModal);
      setTimeout(function () {
        el.runActionCommand.focus();
      }, 0);
    });

    on(el.runActionClose, "click", function () {
      closeModal(el.runActionModal);
    });

    on(el.runActionModal, "click", function (event) {
      if (event.target === el.runActionModal) {
        closeModal(el.runActionModal);
      }
    });

    on(el.runActionForm, "submit", function (event) {
      event.preventDefault();
      var commandText = el.runActionCommand.value;
      if (!trim(commandText)) {
        return;
      }
      var submitter = event.submitter || (el.runActionForm && el.runActionForm.querySelector("button[type='submit']"));
      runWithControlPending(submitter, function () {
        openTerminal();
        return runCommandViaApi(commandText, "run_action")
          .then(function () {
            closeModal(el.runActionModal);
            el.runActionCommand.value = "";
          });
      }).catch(showError);
    });

    on(el.settingsBtn, "click", function () {
      runWithControlPending(el.settingsBtn, function () {
        return openSettingsModal();
      }, { spinner: false }).catch(showError);
    });

    on(el.settingsCloseBtn, "click", function () {
      closeModal(el.settingsModal);
    });

    if (el.multi_agentModalClose) {
      on(el.multi_agentModalClose, "click", function () {
        closeModal(el.multi_agentModal);
      });
    }

    if (el.multi_agentCharter) {
      on(el.multi_agentCharter, "input", function () {
        var wsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
        if (!wsId) {
          return;
        }
        scheduleMultiAgentCharterSave(wsId, 700);
      });
      on(el.multi_agentCharter, "blur", function () {
        var wsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
        if (!wsId) {
          return;
        }
        scheduleMultiAgentCharterSave(wsId, 0);
      });
    }

    on(el.settingsModal, "click", function (event) {
      var deleteBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='delete-command-rule'][data-rule-scope][data-rule-index]")
        : null;
      if (deleteBtn) {
        var wsDeleteId = String(state.commandRulesWorkspaceId || "");
        var deleteScope = deleteBtn.getAttribute("data-rule-scope") || "";
        var deleteIndex = deleteBtn.getAttribute("data-rule-index") || "";
        runWithControlPending(deleteBtn, function () {
          return deleteCommandRule(wsDeleteId, deleteScope, deleteIndex);
        }, { spinner: false }).catch(showError);
        return;
      }
      var clearBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='clear-command-rules'][data-rule-scope]")
        : null;
      if (clearBtn) {
        var wsClearId = String(state.commandRulesWorkspaceId || "");
        var clearScope = clearBtn.getAttribute("data-rule-scope") || "";
        if (!wsClearId || !clearScope) {
          return;
        }
        var confirmText = clearScope === "remember"
          ? "Clear all remembered approval rules for this project?"
          : "Clear all one-time approval rules for this project?";
        if (!window.confirm(confirmText)) {
          return;
        }
        runWithControlPending(clearBtn, function () {
          return clearCommandRules(wsClearId, clearScope);
        }, { spinner: false }).catch(showError);
        return;
      }
      var modeToggleBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='mode-runtime-toggle'][data-mode-id][data-enabled]")
        : null;
      if (modeToggleBtn) {
        var modeToggleId = modeToggleBtn.getAttribute("data-mode-id") || "";
        var modeToggleEnabled = modeToggleBtn.getAttribute("data-enabled") === "1";
        runWithControlPending(modeToggleBtn, function () {
          return modeRuntimeUpdate(modeToggleId, { enabled: modeToggleEnabled });
        }, { spinner: false }).catch(showError);
        return;
      }
      var modeInjectionBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='mode-runtime-injection'][data-mode-id][data-allow]")
        : null;
      if (modeInjectionBtn) {
        var modeInjectionId = modeInjectionBtn.getAttribute("data-mode-id") || "";
        var modeInjectionAllow = modeInjectionBtn.getAttribute("data-allow") === "1";
        runWithControlPending(modeInjectionBtn, function () {
          return modeRuntimeUpdate(modeInjectionId, { allow_queue_injection: modeInjectionAllow });
        }, { spinner: false }).catch(showError);
        return;
      }
      var modeUseBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='mode-runtime-use'][data-mode-id]")
        : null;
      if (modeUseBtn) {
        saveRunMode("assistant");
        saveAssistantModeId(modeUseBtn.getAttribute("data-mode-id") || "");
        if (el.assistantModeSelect) {
          el.assistantModeSelect.value = state.assistantModeId;
        }
        closeModal(el.settingsModal);
        renderUi();
        showTransientNotice("Assistant focus mode updated");
        return;
      }
      var skillQuickBtn = event.target && event.target.closest
        ? event.target.closest("button[data-action='mode-runtime-skill-quick'][data-skill-id]")
        : null;
      if (skillQuickBtn) {
        var quickSkillId = trim(String(skillQuickBtn.getAttribute("data-skill-id") || ""));
        if (el.modeRuntimeSkillSelect) {
          el.modeRuntimeSkillSelect.value = quickSkillId;
        }
        if (el.modeRuntimeSkillInput) {
          el.modeRuntimeSkillInput.focus();
        }
        showTransientNotice("Skill ready: " + quickSkillId);
        return;
      }
      if (event.target === el.settingsModal) {
        closeModal(el.settingsModal);
      }
    });

    if (el.multi_agentModal) {
      on(el.multi_agentModal, "click", function (event) {
        var triageActionBtn = event.target && event.target.closest
          ? event.target.closest("[data-action^='triage-']")
          : null;
        if (triageActionBtn) {
          handleWorkspaceTreeClick(event);
          return;
        }
        var residentOptionsBtn = event.target && event.target.closest
          ? event.target.closest("button[data-action='multi_agent-resident-options-toggle'][data-resident-id]")
          : null;
        if (residentOptionsBtn) {
          var rowSelectBtn = residentOptionsBtn.closest("[data-resident-id]");
          if (rowSelectBtn) {
            var selectedWsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
            var selectedId = trim(String(rowSelectBtn.getAttribute("data-resident-id") || ""));
            if (selectedWsId && selectedId) {
              state.multiAgentSelectedResidentIdByWorkspace[selectedWsId] = selectedId;
            }
          }
          var optResidentId = residentOptionsBtn.getAttribute("data-resident-id") || "";
          var optionsWsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
          if (!optResidentId || !optionsWsId) {
            return;
          }
          if (state.multiAgentOpenResidentOptionsByWorkspace[optionsWsId] === optResidentId) {
            state.multiAgentOpenResidentOptionsByWorkspace[optionsWsId] = "";
          } else {
            state.multiAgentOpenResidentOptionsByWorkspace[optionsWsId] = optResidentId;
          }
          renderMultiAgentModal();
          return;
        }

        var residentRow = event.target && event.target.closest
          ? event.target.closest("[data-action='multi_agent-resident-select'][data-workspace-id][data-resident-id]")
          : null;
        if (residentRow) {
          if (event.target && event.target.closest && event.target.closest("input, select, button, label, textarea, a, summary")) {
            return;
          }
          var rowWsId = residentRow.getAttribute("data-workspace-id") || "";
          var rowResidentId = residentRow.getAttribute("data-resident-id") || "";
          if (rowWsId && rowResidentId) {
            state.multiAgentSelectedResidentIdByWorkspace[rowWsId] = rowResidentId;
            renderMultiAgentModal();
          }
          return;
        }

        var commitmentStatusBtn = event.target && event.target.closest
          ? event.target.closest("button[data-action='multi_agent-commitment-status'][data-workspace-id][data-entry-id][data-status]")
          : null;
        if (commitmentStatusBtn) {
          var commitmentWsId = commitmentStatusBtn.getAttribute("data-workspace-id") || "";
          var commitmentEntryId = commitmentStatusBtn.getAttribute("data-entry-id") || "";
          var commitmentStatus = commitmentStatusBtn.getAttribute("data-status") || "";
          runWithControlPending(commitmentStatusBtn, function () {
            return apiPost("multi_agent_commitment_update", {
              workspace_id: commitmentWsId,
              entry_id: commitmentEntryId,
              status: commitmentStatus
            }).then(function (response) {
              if (!response || !response.success) {
                throw new Error((response && response.error) || "Could not update commitment status");
              }
              state.workspaceMultiAgentById[commitmentWsId] = response.workspace_multi_agent || state.workspaceMultiAgentById[commitmentWsId] || null;
              return loadState();
            }).then(renderUi);
          }).catch(showError);
          return;
        }

        var logDeleteBtn = event.target && event.target.closest
          ? event.target.closest("button[data-action='multi_agent-log-delete'][data-workspace-id][data-log-kind][data-entry-id]")
          : null;
        if (logDeleteBtn) {
          var deleteWsId = logDeleteBtn.getAttribute("data-workspace-id") || "";
          var logKind = logDeleteBtn.getAttribute("data-log-kind") || "";
          var entryId = logDeleteBtn.getAttribute("data-entry-id") || "";
          runWithControlPending(logDeleteBtn, function () {
            return apiPost("multi_agent_log_delete", {
              workspace_id: deleteWsId,
              log_kind: logKind,
              entry_id: entryId
            }).then(function (response) {
              if (!response || !response.success) {
                throw new Error((response && response.error) || "Could not delete entry");
              }
              state.workspaceMultiAgentById[deleteWsId] = response.workspace_multi_agent || state.workspaceMultiAgentById[deleteWsId] || null;
              return loadState();
            }).then(renderUi);
          }).catch(showError);
          return;
        }

        if (event.target === el.multi_agentModal) {
          closeModal(el.multi_agentModal);
        }
      });

      on(el.multi_agentModal, "change", function (event) {
        var toggleInput = event.target && event.target.closest
          ? event.target.closest("#multi_agent-toggle-amendments, #multi_agent-toggle-commitments, #multi_agent-toggle-policies")
          : null;
        if (toggleInput) {
          var wsId = trim(String(state.commandRulesWorkspaceId || state.activeWorkspaceId || ""));
          if (!wsId) {
            return;
          }
          multiAgentSectionVisibilitySync();
          saveMultiAgentGovernanceFromControls(wsId)
            .then(function () { return loadState(); })
            .then(renderUi)
            .catch(showError);
          return;
        }

        var residentEnableInput = event.target && event.target.closest
          ? event.target.closest("input[data-action='multi_agent-resident-enable'][data-workspace-id][data-resident-id]")
          : null;
        if (residentEnableInput) {
          var wsEnable = residentEnableInput.getAttribute("data-workspace-id") || "";
          var residentEnableId = residentEnableInput.getAttribute("data-resident-id") || "";
          if (wsEnable && residentEnableId) {
            state.multiAgentSelectedResidentIdByWorkspace[wsEnable] = residentEnableId;
          }
          var checked = !!residentEnableInput.checked;
          var modelSelect = null;
          var visibleInput = null;
          if (el.multi_agentModal) {
            var residentModelSelects = el.multi_agentModal.querySelectorAll("select[data-action='multi_agent-resident-model'][data-workspace-id][data-resident-id]");
            for (var rms = 0; rms < residentModelSelects.length; rms += 1) {
              if (
                String(residentModelSelects[rms].getAttribute("data-workspace-id") || "") === String(wsEnable) &&
                String(residentModelSelects[rms].getAttribute("data-resident-id") || "") === String(residentEnableId)
              ) {
                modelSelect = residentModelSelects[rms];
                break;
              }
            }
            var residentVisibleInputs = el.multi_agentModal.querySelectorAll("input[data-action='multi_agent-resident-visible'][data-workspace-id][data-resident-id]");
            for (var rvi = 0; rvi < residentVisibleInputs.length; rvi += 1) {
              if (
                String(residentVisibleInputs[rvi].getAttribute("data-workspace-id") || "") === String(wsEnable) &&
                String(residentVisibleInputs[rvi].getAttribute("data-resident-id") || "") === String(residentEnableId)
              ) {
                visibleInput = residentVisibleInputs[rvi];
                break;
              }
            }
          }
          var selectedModel = trim(String(modelSelect && modelSelect.value || ""));
          var showInThreads = !!(visibleInput && visibleInput.checked);
          var residentState = state.workspaceMultiAgentById[wsEnable];
          var existingResidents = Array.isArray(residentState && residentState.residents) ? residentState.residents : [];
          var alreadyExists = false;
          for (var ri = 0; ri < existingResidents.length; ri += 1) {
            if (String(existingResidents[ri] && existingResidents[ri].id || "") === residentEnableId) {
              alreadyExists = true;
              break;
            }
          }
          var enablePromise = null;
          if (checked && !alreadyExists) {
            enablePromise = apiPost("multi_agent_resident_spawn", {
              workspace_id: wsEnable,
              resident_id: residentEnableId,
              visible: showInThreads ? "1" : "0",
              background: showInThreads ? "0" : "1",
              reserve_compute: "0",
              model: selectedModel
            });
          } else {
            var updatePayload = {
              workspace_id: wsEnable,
              resident_id: residentEnableId,
              enabled: checked ? "1" : "0",
              visible: showInThreads ? "1" : "0",
              background: showInThreads ? "0" : "1"
            };
            if (selectedModel) {
              updatePayload.model = selectedModel;
            }
            enablePromise = apiPost("multi_agent_resident_update", updatePayload);
          }
          enablePromise.then(function (response) {
            if (!response || !response.success) {
              throw new Error((response && response.error) || "Could not update agent role");
            }
            state.workspaceMultiAgentById[wsEnable] = response.workspace_multi_agent || state.workspaceMultiAgentById[wsEnable] || null;
            return loadState();
          }).then(renderUi).catch(showError);
          return;
        }

        var residentVisibleInput = event.target && event.target.closest
          ? event.target.closest("input[data-action='multi_agent-resident-visible'][data-workspace-id][data-resident-id]")
          : null;
        if (residentVisibleInput) {
          var wsVisible = residentVisibleInput.getAttribute("data-workspace-id") || "";
          var residentVisibleId = residentVisibleInput.getAttribute("data-resident-id") || "";
          if (wsVisible && residentVisibleId) {
            state.multiAgentSelectedResidentIdByWorkspace[wsVisible] = residentVisibleId;
          }
          var showThreads = residentVisibleInput.checked ? "1" : "0";
          apiPost("multi_agent_resident_update", {
            workspace_id: wsVisible,
            resident_id: residentVisibleId,
            visible: showThreads,
            background: showThreads === "1" ? "0" : "1"
          }).then(function (response) {
            if (!response || !response.success) {
              throw new Error((response && response.error) || "Could not update agent visibility");
            }
            state.workspaceMultiAgentById[wsVisible] = response.workspace_multi_agent || state.workspaceMultiAgentById[wsVisible] || null;
            return loadState();
          }).then(renderUi).catch(showError);
          return;
        }

        var residentModelSelect = event.target && event.target.closest
          ? event.target.closest("select[data-action='multi_agent-resident-model'][data-workspace-id][data-resident-id]")
          : null;
        if (residentModelSelect) {
          var wsModel = residentModelSelect.getAttribute("data-workspace-id") || "";
          var residentModelId = residentModelSelect.getAttribute("data-resident-id") || "";
          if (wsModel && residentModelId) {
            state.multiAgentSelectedResidentIdByWorkspace[wsModel] = residentModelId;
          }
          var modelValue = trim(String(residentModelSelect.value || ""));
          if (!modelValue) {
            return;
          }
          apiPost("multi_agent_resident_update", {
            workspace_id: wsModel,
            resident_id: residentModelId,
            model: modelValue
          }).then(function (response) {
            if (!response || !response.success) {
              throw new Error((response && response.error) || "Could not update agent model");
            }
            state.workspaceMultiAgentById[wsModel] = response.workspace_multi_agent || state.workspaceMultiAgentById[wsModel] || null;
            return loadState();
          }).then(renderUi).catch(showError);
        }
      });
    }

    if (el.commandRulesWorkspace) {
      on(el.commandRulesWorkspace, "change", function () {
        var wsId = trim(el.commandRulesWorkspace.value || "");
        state.commandRulesWorkspaceId = wsId;
        loadCommandRules(wsId).catch(showError);
      });
    }

    on(el.refreshAuthBtn, "click", function () {
      runWithControlPending(el.refreshAuthBtn, function () {
        return loadAuthStatus();
      }).catch(showError);
    });

    if (el.modeRuntimeTickBtn) {
      on(el.modeRuntimeTickBtn, "click", function () {
        runWithControlPending(el.modeRuntimeTickBtn, function () {
          return modeRuntimeTickNow();
        }, { spinner: false }).catch(showError);
      });
    }

    if (el.assistantModeApplyBtn) {
      on(el.assistantModeApplyBtn, "click", function () {
        var selectedModeId = trim(String((el.assistantModeSelect && el.assistantModeSelect.value) || ""));
        saveRunMode("assistant");
        saveAssistantModeId(selectedModeId);
        renderUi();
        showTransientNotice(selectedModeId ? "Assistant focus mode applied" : "Assistant general mode applied");
      });
    }

    if (el.modeRuntimeSkillInvokeForm) {
      on(el.modeRuntimeSkillInvokeForm, "submit", function (event) {
        event.preventDefault();
        var skillId = trim(String((el.modeRuntimeSkillSelect && el.modeRuntimeSkillSelect.value) || ""));
        if (!skillId) {
          setModeRuntimeSkillResult("Select a skill first.", true);
          return;
        }
        var modeId = trim(String((el.modeRuntimeSkillMode && el.modeRuntimeSkillMode.value) || "")) || "assistant";
        var inputText = String((el.modeRuntimeSkillInput && el.modeRuntimeSkillInput.value) || "");
        var capabilitiesCsv = trim(String((el.modeRuntimeSkillCapabilities && el.modeRuntimeSkillCapabilities.value) || ""));
        runWithControlPending(el.modeRuntimeSkillInvokeBtn || event.submitter, function () {
          setModeRuntimeSkillResult("Invoking skill...", false);
          return modeRuntimeSkillInvoke(modeId, skillId, inputText, capabilitiesCsv);
        }, { spinner: false }).catch(function (error) {
          setModeRuntimeSkillResult(error && error.message ? error.message : String(error), true);
        });
      });
    }

    if (el.modeRuntimeSkillCreateForm) {
      on(el.modeRuntimeSkillCreateForm, "submit", function (event) {
        event.preventDefault();
        var payload = {
          skill_id: trim(String((el.modeRuntimeSkillCreateId && el.modeRuntimeSkillCreateId.value) || "")),
          name: trim(String((el.modeRuntimeSkillCreateName && el.modeRuntimeSkillCreateName.value) || "")),
          trigger: trim(String((el.modeRuntimeSkillCreateTrigger && el.modeRuntimeSkillCreateTrigger.value) || "")),
          capabilities: trim(String((el.modeRuntimeSkillCreateCapabilities && el.modeRuntimeSkillCreateCapabilities.value) || "")),
          description: trim(String((el.modeRuntimeSkillCreateDescription && el.modeRuntimeSkillCreateDescription.value) || ""))
        };
        if (!payload.skill_id) {
          setModeRuntimeSkillResult("Provide a new skill id.", true);
          return;
        }
        runWithControlPending(el.modeRuntimeSkillCreateBtn || event.submitter, function () {
          return modeRuntimeSkillCreate(payload).then(function () {
            showTransientNotice("Skill created: " + payload.skill_id);
            setModeRuntimeSkillResult("Created skill bundle " + payload.skill_id + ".", false);
            if (el.modeRuntimeSkillCreateForm) {
              el.modeRuntimeSkillCreateForm.reset();
            }
          });
        }, { spinner: false }).catch(function (error) {
          setModeRuntimeSkillResult(error && error.message ? error.message : String(error), true);
        });
      });
    }

    if (el.modeRuntimeSkillInstallForm) {
      on(el.modeRuntimeSkillInstallForm, "submit", function (event) {
        event.preventDefault();
        var payload = {
          source_path: trim(String((el.modeRuntimeSkillInstallSource && el.modeRuntimeSkillInstallSource.value) || "")),
          skill_id: trim(String((el.modeRuntimeSkillInstallId && el.modeRuntimeSkillInstallId.value) || "")),
          replace: String((el.modeRuntimeSkillInstallReplace && el.modeRuntimeSkillInstallReplace.value) || "0") === "1"
        };
        if (!payload.source_path) {
          setModeRuntimeSkillResult("Provide a source folder path.", true);
          return;
        }
        runWithControlPending(el.modeRuntimeSkillInstallBtn || event.submitter, function () {
          return modeRuntimeSkillInstall(payload).then(function (response) {
            var installedId = trim(String((response && response.skill_id) || payload.skill_id || ""));
            showTransientNotice("Skill installed" + (installedId ? ": " + installedId : ""));
            setModeRuntimeSkillResult("Installed skill bundle " + (installedId || "from source") + ".", false);
            if (el.modeRuntimeSkillInstallForm) {
              el.modeRuntimeSkillInstallForm.reset();
            }
          });
        }, { spinner: false }).catch(function (error) {
          setModeRuntimeSkillResult(error && error.message ? error.message : String(error), true);
        });
      });
    }

    if (el.githubUsername) {
      on(el.githubUsername, "input", function () {
        state.githubUsername = trim(el.githubUsername.value);
        storageSet("artificer.githubUsername", state.githubUsername);
      });
    }

    on(el.generateSshBtn, "click", function () {
      runWithControlPending(el.generateSshBtn, function () {
        return apiPost("git_generate_ssh", { email: trim(el.sshEmail.value) })
          .then(function (response) {
            if (!response.success) {
              throw new Error(response.error || "Could not generate SSH key");
            }
            el.sshPubOutput.value = response.ssh_pub_key || "";
            el.sshKeyStatus.textContent = "SSH key ready";
          });
      }).catch(showError);
    });

    if (el.chooseSshBtn) {
      on(el.chooseSshBtn, "click", function () {
        runWithControlPending(el.chooseSshBtn, function () {
          return apiPost("git_choose_ssh_key", {})
            .then(function (response) {
              if (!response.success) {
                throw new Error(response.error || "Could not choose SSH key");
              }
              if (response.cancelled) {
                return null;
              }
              if (el.selectedSshPath) {
                el.selectedSshPath.value = response.selected_ssh_pub_path || "";
              }
              if (el.sshPubOutput && typeof response.selected_ssh_pub_key !== "undefined") {
                el.sshPubOutput.value = response.selected_ssh_pub_key || "";
              }
              if (el.sshKeyStatus) {
                el.sshKeyStatus.textContent = response.selected_ssh_pub_path ? "Custom SSH key selected" : "SSH key found";
              }
              return null;
            });
        }).catch(showError);
      });
    }

    if (el.clearSshBtn) {
      on(el.clearSshBtn, "click", function () {
        runWithControlPending(el.clearSshBtn, function () {
          return apiPost("git_clear_ssh_key", {})
            .then(function (response) {
              if (!response.success) {
                throw new Error(response.error || "Could not clear SSH key selection");
              }
              return loadAuthStatus();
            });
        }).catch(showError);
      });
    }

    on(el.terminalToggleBtn, "click", function () {
      toggleTerminal();
    });

    if (el.terminalPanel) {
      on(el.terminalPanel, "click", function () {
        if (el.terminalOutput) {
          el.terminalOutput.focus();
        }
      });
    }

    on(el.terminalPanel, "keydown", function (event) {
      if (!state.terminalOpen) {
        return;
      }
      if (event.metaKey || event.ctrlKey) {
        return;
      }
      if (event.altKey) {
        return;
      }

      if (event.key === "Enter") {
        event.preventDefault();
        var commandText = String(state.terminalInputBuffer || "");
        state.terminalInputBuffer = "";
        renderTerminal();
        if (!trim(commandText)) {
          return;
        }
        state.terminalBusy = true;
        renderTerminal();
        ensureTerminalSession()
          .then(function () {
            return apiPost("terminal_session_input", {
              workspace_id: state.activeWorkspaceId,
              session_id: state.terminalSessionId,
              input: commandText + "\n"
            }, { timeoutMs: 10000 });
          })
          .then(function (response) {
            if (!response || !response.success) {
              throw new Error((response && response.error) || "Could not send terminal input");
            }
            return pollTerminalSessionOnce();
          })
          .finally(function () {
            state.terminalBusy = false;
            renderTerminal();
          })
          .catch(showError);
        return;
      }

      if (event.key === "Backspace") {
        event.preventDefault();
        state.terminalInputBuffer = String(state.terminalInputBuffer || "").slice(0, -1);
        renderTerminal();
        return;
      }

      if (event.key === "Escape") {
        event.preventDefault();
        state.terminalInputBuffer = "";
        renderTerminal();
        return;
      }

      if (event.key === "Tab") {
        event.preventDefault();
        state.terminalInputBuffer += "  ";
        renderTerminal();
        return;
      }

      if (event.key && event.key.length === 1) {
        event.preventDefault();
        state.terminalInputBuffer += event.key;
        renderTerminal();
      }
    });

    on(el.terminalPanel, "paste", function (event) {
      if (!state.terminalOpen) {
        return;
      }
      var text = event.clipboardData && event.clipboardData.getData ? event.clipboardData.getData("text") : "";
      if (!text) {
        return;
      }
      event.preventDefault();
      var chunk = String(text).replace(/\r?\n/g, " ");
      state.terminalInputBuffer += chunk;
      renderTerminal();
    });

    on(el.changesBtn, "click", function () {
      if (!state.activeWorkspaceId) {
        showError(new Error("Select a project first."));
        return;
      }
      runWithControlPending(el.changesBtn, function () {
        return toggleDiffPanel();
      }, { spinner: false }).catch(showError);
    });

    on(el.diffCloseBtn, "click", function () {
      closeDiffPanel();
    });

    on(el.runForm, "submit", function (event) {
      onRunSubmit(event);
    });

    on(el.decisionRequestInlineClose, "click", function () {
      var info = activeDecisionRequestInfo();
      if (info) {
        state.decisionInlineDismissedKey = info.marker;
      }
      if (el.decisionRequestInline) {
        el.decisionRequestInline.classList.add("hidden");
      }
    });

    on(el.decisionRequestOptions, "change", function () {
      updateDecisionOtherVisibility();
    });

    on(el.decisionRequestOtherInput, "input", function () {
      if (!el.decisionRequestOptions) {
        return;
      }
      var otherRadio = el.decisionRequestOptions.querySelector("input[name='decision-request-choice'][value='other']");
      if (otherRadio) {
        otherRadio.checked = true;
      }
      updateDecisionOtherVisibility();
    });

    on(el.decisionRequestForm, "submit", function (event) {
      event.preventDefault();
      var submitter = event.submitter || el.decisionRequestSubmit;
      runWithControlPending(submitter, function () {
        return submitDecisionRequest();
      }).catch(showError);
    });

    if (el.attachBtn && el.attachmentPicker) {
      on(el.attachBtn, "click", function () {
        el.attachmentPicker.click();
      });
      on(el.attachmentPicker, "change", function (event) {
        try {
          onAttachmentPickerChange(event);
        } catch (error) {
          showError(error);
        }
      });
    }

    if (el.attachmentStrip) {
      on(el.attachmentStrip, "click", function (event) {
        handleAttachmentStripClick(event);
      });
      on(el.attachmentStrip, "keydown", function (event) {
        handleAttachmentStripKeydown(event);
      });
    }

    if (el.runForm) {
      on(el.runForm, "dragenter", function (event) {
        onComposerDragEnter(event);
      });
      on(el.runForm, "dragover", function (event) {
        onComposerDragOver(event);
      });
      on(el.runForm, "dragleave", function (event) {
        onComposerDragLeave(event);
      });
      on(el.runForm, "drop", function (event) {
        try {
          onComposerDropped(event);
        } catch (error) {
          showError(error);
        }
      });
    }

    on(el.chatLog, "click", function (event) {
      var triageAction = event.target.closest("[data-action^='triage-']");
      if (triageAction) {
        handleWorkspaceTreeClick(event);
        return;
      }
      var stopBtn = event.target.closest("[data-action='stop-run'][data-workspace-id][data-conversation-id]");
      if (stopBtn) {
        event.preventDefault();
        var stopWorkspaceId = stopBtn.getAttribute("data-workspace-id") || "";
        var stopConversationId = stopBtn.getAttribute("data-conversation-id") || "";
        runWithControlPending(stopBtn, function () {
          return stopConversationRun(stopWorkspaceId, stopConversationId);
        }).catch(showError);
        return;
      }

      var copyBtn = event.target.closest("[data-action='copy-user-message']");
      if (!copyBtn) {
        return;
      }
      event.preventDefault();
      var text = copyBtn.getAttribute("data-copy-text") || "";
      copyTextToClipboard(text).then(function () {
        copyBtn.classList.add("copied");
        showTransientNotice("Copied text", { transparent: true });
        window.setTimeout(function () {
          copyBtn.classList.remove("copied");
        }, 900);
      });
    });

    if (el.chatLog) {
      el.chatLog.addEventListener("toggle", function (event) {
        var panel = event.target;
        if (!panel || !panel.matches || !panel.matches("details.run-details[data-event-id]")) {
          return;
        }
        var eventId = String(panel.getAttribute("data-event-id") || "");
        if (!eventId) {
          return;
        }
        state.runDetailsOpenByEventId[eventId] = panel.open ? 1 : 0;
        if (panel.open) {
          var preview = panel.querySelector(".run-live-feed");
          if (preview) {
            preview.scrollTop = preview.scrollHeight;
            state.runStreamAutoFollowByEventId[eventId] = true;
            state.runStreamScrollTopByEventId[eventId] = preview.scrollTop;
          }
        }
      }, true);
      el.chatLog.addEventListener("scroll", function (event) {
        var target = event && event.target;
        if (!target || !target.classList || !target.classList.contains("run-live-feed")) {
          return;
        }
        var panel = target.closest("details.run-details.run-thinking[data-event-id]");
        if (!panel) {
          return;
        }
        var eventId = String(panel.getAttribute("data-event-id") || "");
        if (!eventId) {
          return;
        }
        state.runStreamScrollTopByEventId[eventId] = Number(target.scrollTop || 0);
        state.runStreamAutoFollowByEventId[eventId] = isElementScrollAtBottom(target, 8);
      }, true);
    }

    on(el.chatLog, "scroll", function () {
      state.chatAutoScroll = isChatAtBottom();
      updateChatJumpButton();
    });

    on(el.chatJumpBottomBtn, "click", function () {
      jumpChatToBottom();
    });

    if (el.queueTray) {
      on(el.queueTray, "click", function (event) {
        var wsId = String(state.activeWorkspaceId || "");
        var convId = String(state.activeConversationId || "");
        if (!wsId || !convId) {
          return;
        }

        var steerBtn = event.target.closest("[data-action='queue-steer-item'][data-queue-item-id]");
        if (steerBtn) {
          event.preventDefault();
          var steerItemId = steerBtn.getAttribute("data-queue-item-id") || "";
          runWithControlPending(steerBtn, function () {
            return steerQueuedMessage(steerItemId, {
              workspaceId: wsId,
              conversationId: convId,
              interruptRunning: true
            });
          }).catch(showError);
          return;
        }

        var trashBtn = event.target.closest("[data-action='queue-trash-item'][data-queue-item-id]");
        if (trashBtn) {
          event.preventDefault();
          var trashItemId = trashBtn.getAttribute("data-queue-item-id") || "";
          runWithControlPending(trashBtn, function () {
            return cancelQueuedMessage(trashItemId, {
              workspaceId: wsId,
              conversationId: convId
            });
          }).catch(showError);
          return;
        }

        var editBtn = event.target.closest("[data-action='queue-edit-item'][data-queue-item-id]");
        if (editBtn) {
          event.preventDefault();
          var editItemId = editBtn.getAttribute("data-queue-item-id") || "";
          var queueItems = queueItemsForConversation(wsId, convId);
          var editPrompt = "";
          for (var i = 0; i < queueItems.length; i += 1) {
            if (String((queueItems[i] && queueItems[i].id) || "") === String(editItemId)) {
              editPrompt = String((queueItems[i] && queueItems[i].prompt) || "");
              break;
            }
          }
          beginQueueItemEdit(wsId, convId, editItemId, editPrompt);
          renderUi();
          setTimeout(function () {
            var field = el.queueTray.querySelector("textarea[data-action='queue-edit-input'][data-queue-item-id='" + escAttr(editItemId) + "']");
            if (field) {
              field.focus();
              field.selectionStart = field.value.length;
              field.selectionEnd = field.value.length;
            }
          }, 0);
          return;
        }

        var saveBtn = event.target.closest("[data-action='queue-edit-save'][data-queue-item-id]");
        if (saveBtn) {
          event.preventDefault();
          var saveItemId = saveBtn.getAttribute("data-queue-item-id") || "";
          if (!isQueueEditForConversation(wsId, convId) || String(state.queueEdit.itemId || "") !== String(saveItemId)) {
            return;
          }
          if (state.queueEdit.saving) {
            return;
          }
          state.queueEdit.saving = true;
          renderUi();
          updateQueuedMessage(saveItemId, state.queueEdit.draftText, {
            workspaceId: wsId,
            conversationId: convId
          })
            .then(function () {
              clearQueueEditState();
              showTransientNotice("Queued message updated");
              renderUi();
              kickQueueWorker();
            })
            .catch(function (error) {
              state.queueEdit.saving = false;
              renderUi();
              showError(error);
            });
          return;
        }

        var cancelBtn = event.target.closest("[data-action='queue-edit-cancel'][data-queue-item-id]");
        if (cancelBtn) {
          event.preventDefault();
          clearQueueEditState();
          renderUi();
          kickQueueWorker();
        }
      });

      on(el.queueTray, "input", function (event) {
        var input = event.target.closest("textarea[data-action='queue-edit-input'][data-queue-item-id]");
        if (!input) {
          return;
        }
        var itemId = String(input.getAttribute("data-queue-item-id") || "");
        if (!itemId || String(state.queueEdit.itemId || "") !== itemId) {
          return;
        }
        state.queueEdit.draftText = String(input.value || "");
      });

      on(el.queueTray, "keydown", function (event) {
        var input = event.target.closest("textarea[data-action='queue-edit-input'][data-queue-item-id]");
        if (!input) {
          return;
        }
        var itemId = String(input.getAttribute("data-queue-item-id") || "");
        if (!itemId || String(state.queueEdit.itemId || "") !== itemId) {
          return;
        }
        if (event.key === "Escape") {
          event.preventDefault();
          clearQueueEditState();
          renderUi();
          kickQueueWorker();
          return;
        }
        if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
          event.preventDefault();
          if (state.queueEdit.saving) {
            return;
          }
          state.queueEdit.saving = true;
          renderUi();
          updateQueuedMessage(itemId, state.queueEdit.draftText, {
            workspaceId: String(state.activeWorkspaceId || ""),
            conversationId: String(state.activeConversationId || "")
          })
            .then(function () {
              clearQueueEditState();
              showTransientNotice("Queued message updated");
              renderUi();
              kickQueueWorker();
            })
            .catch(function (error) {
              state.queueEdit.saving = false;
              renderUi();
              showError(error);
            });
        }
      });
    }

    if (el.runTodoMonitor) {
      el.runTodoMonitor.addEventListener("toggle", function () {
        if (!state.activeWorkspaceId || !state.activeConversationId) {
          return;
        }
        var todoKey = queueConversationKey(state.activeWorkspaceId, state.activeConversationId);
        if (!todoKey) {
          return;
        }
        state.runTodoMonitorOpenByConversation[todoKey] = el.runTodoMonitor.open ? 1 : 0;
      });
    }

    if (el.runTerminalMonitor) {
      el.runTerminalMonitor.addEventListener("toggle", function () {
        if (!state.activeWorkspaceId || !state.activeConversationId) {
          return;
        }
        var key = queueConversationKey(state.activeWorkspaceId, state.activeConversationId);
        if (!key) {
          return;
        }
        state.runTerminalMonitorOpenByConversation[key] = el.runTerminalMonitor.open ? 1 : 0;
      });
    }

    if (el.runTerminalMonitorStop) {
      on(el.runTerminalMonitorStop, "click", function (event) {
        event.preventDefault();
        event.stopPropagation();
        var wsId = String(el.runTerminalMonitorStop.dataset.workspaceId || state.activeWorkspaceId || "");
        var convId = String(el.runTerminalMonitorStop.dataset.conversationId || state.activeConversationId || "");
        if (!wsId || !convId) {
          return;
        }
        runWithControlPending(el.runTerminalMonitorStop, function () {
          return stopConversationRun(wsId, convId);
        }).catch(showError);
      });
    }

    if (el.queueSteerBtn) {
      on(el.queueSteerBtn, "click", function () {
        var fallbackItemId = trim((el.queueSteerBtn && el.queueSteerBtn.dataset.queueItemId) || "");
        runWithControlPending(el.queueSteerBtn, function () {
          return steerQueuedMessage(fallbackItemId, {
            workspaceId: state.activeWorkspaceId,
            conversationId: state.activeConversationId,
            interruptRunning: true
          });
        }).catch(showError);
      });
    }

    if (el.queueCancelBtn) {
      on(el.queueCancelBtn, "click", function () {
        var fallbackItemId = trim((el.queueCancelBtn && el.queueCancelBtn.dataset.queueItemId) || "");
        runWithControlPending(el.queueCancelBtn, function () {
          return cancelQueuedMessage(fallbackItemId, {
            workspaceId: state.activeWorkspaceId,
            conversationId: state.activeConversationId
          });
        }).catch(showError);
      });
    }

    on(el.runPrompt, "input", function () {
      if (state.activeDraftWorkspaceId) {
        state.draftTextByWorkspace[state.activeDraftWorkspaceId] = el.runPrompt.value;
        saveDraftDebounced();
      }
      renderRunButton();
    });

    on(el.runPrompt, "paste", function (event) {
      try {
        onPromptPaste(event);
      } catch (error) {
        showError(error);
      }
    });

    on(el.runPrompt, "keydown", function (event) {
      if (event.key !== "Enter") {
        return;
      }
      if (event.shiftKey || event.altKey) {
        return;
      }

      var hasModifier = !!(event.metaKey || event.ctrlKey);
      var text = String(el.runPrompt.value || "");
      var hasNewline = text.indexOf("\n") >= 0;

      if (!hasModifier && hasNewline) {
        return;
      }

      event.preventDefault();
      if (el.runForm && typeof el.runForm.requestSubmit === "function") {
        el.runForm.requestSubmit();
      } else if (el.runForm) {
        onRunSubmit(event);
      }
    });

    document.addEventListener("click", function (event) {
      if (Date.now() < suppressMenuCloseUntilMs) {
        return;
      }
      if (!event.target || typeof event.target.closest !== "function") {
        closeAllMenus();
        return;
      }
      if (
        event.target.closest("#model-status-btn") ||
        event.target.closest(".menu-anchor") ||
        event.target.closest(".models-pane") ||
        event.target.closest(".models-box") ||
        event.target.closest("#organize-menu") ||
        event.target.closest("#organize-btn") ||
        event.target.closest(".workspace-menu-trigger") ||
        event.target.closest("[data-workspace-menu]") ||
        event.target.closest("[data-triage-scope-menu]") ||
        event.target.closest("[data-action='triage-suppress-open']")
      ) {
        return;
      }
      if (state.openTriageSuppressProposalId) {
        state.openTriageSuppressProposalId = "";
      }
      state.openWorkspaceMenuWorkspaceId = "";
      closeAllMenus();
      renderUi();
    });

    document.addEventListener("keydown", function (event) {
      if (event.key !== "Escape") {
        return;
      }

      if (state.pickingWorkspace) {
        return;
      }

      if (!el.runActionModal.classList.contains("hidden")) {
        closeModal(el.runActionModal);
        return;
      }
      if (!el.commitModal.classList.contains("hidden")) {
        closeModal(el.commitModal);
        return;
      }
      if (!el.settingsModal.classList.contains("hidden")) {
        closeModal(el.settingsModal);
        return;
      }
      if (!el.commandApprovalModal.classList.contains("hidden")) {
        closeModal(el.commandApprovalModal);
        return;
      }
      if (pendingCommandApproval && typeof pendingCommandApproval.cancel === "function") {
        pendingCommandApproval.cancel(new Error("Command approval cancelled"));
        return;
      }
      if (!el.workspaceModal.classList.contains("hidden")) {
        closeModal(el.workspaceModal);
        return;
      }

      closeAllMenus();
    });
  }

  window.addEventListener("beforeunload", function () {
    var unloadWorkspaceId = String(state.terminalSessionWorkspaceId || state.activeWorkspaceId || "");
    var unloadSessionId = String(state.terminalSessionId || "");
    stopTerminalPolling();
    if (unloadWorkspaceId && unloadSessionId) {
      apiPost("terminal_session_stop", {
        workspace_id: unloadWorkspaceId,
        session_id: unloadSessionId
      }, { timeoutMs: 1200 }).catch(function () {
        return null;
      });
    }
    if (liveRunTickTimer) {
      clearInterval(liveRunTickTimer);
      liveRunTickTimer = null;
    }
    stopModelInstallPolling();
    stopModelAutoRefreshLoop();
    stopRunEventHealLoop();
    stopApprovalResumeWatch();
    clearPendingAttachments();
  });

  try {
    hydrateWorkspaceStateFromCache();
  } catch (cacheErr) {
    if (window && window.console && typeof window.console.warn === "function") {
      window.console.warn("Artificer cache hydrate failed:", cacheErr);
    }
  }

  try {
    bindEvents();
  } catch (bindErr) {
    if (window && window.console && typeof window.console.error === "function") {
      window.console.error("Artificer bindEvents failed:", bindErr);
    }
  }

  try {
    renderUi();
  } catch (renderErr) {
    if (window && window.console && typeof window.console.error === "function") {
      window.console.error("Artificer renderUi failed:", renderErr);
    }
  }

  refreshAll()
    .catch(function (error) {
      if (!isRetriableRequestError(error)) {
        throw error;
      }
      return waitMs(320).then(function () {
        return refreshAll();
      });
    })
    .then(function () {
      kickQueueWorker();
      startModelAutoRefreshLoop();
      startRunEventHealLoop();
      if (typeof window !== "undefined") {
        window.__artificerBooted = true;
      }
    })
    .catch(function (error) {
      state.initialLoadComplete = true;
      startRunEventHealLoop();
      state.queueWorkerActive = false;
      kickQueueWorker();
      showError(error);
    });
})();
