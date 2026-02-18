(function () {
  "use strict";

  if (typeof window !== "undefined") {
    window.__artificerBooted = "loading";
  }

  var seenConversationStorageKey = "artificer.conversationSeenUpdated";

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

  function parseStoredPaneWidth(key, fallback) {
    var raw = Number(storageGet(key, String(fallback)));
    if (!isFinite(raw) || raw <= 0) {
      return fallback;
    }
    return Math.round(raw);
  }

  var initialSeenConversationState = loadSeenConversationState();

  var state = {
    models: [],
    workspaces: [],
    activeWorkspaceId: "",
    activeConversationId: "",
    activeConversation: null,
    activeDraftWorkspaceId: "",
    draftTextByWorkspace: {},
    draftModelByWorkspace: {},
    runEventsByConversation: {},
    expandedWorkspaceIds: {},
    busy: false,
    pickingWorkspace: false,
    sortMode: storageGet("artificer.workspaceSort", "updated"),
    organizeMode: storageGet("artificer.organizeMode", "project"),
    organizeShow: storageGet("artificer.organizeShow", "all"),
    permissionMode: storageGet("artificer.permissionMode", "default"),
    commandExecMode: storageGet("artificer.commandExecMode", "ask"),
    githubUsername: storageGet("artificer.githubUsername", ""),
    networkAccess: storageGet("artificer.networkAccess", "0") === "1",
    webAccess: storageGet("artificer.webAccess", "0") === "1",
    agentLoopEnabled: storageGet("artificer.agentLoopEnabled", "1") !== "0",
    reasoningEffort: storageGet("artificer.reasoningEffort", "medium"),
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
    contextWindowText: "Context window information will display here.",
    lastErrorText: "",
    lastErrorAt: 0,
    initialLoadComplete: false,
    selectionVersion: 0,
    chatAutoScroll: true,
    chatLastKey: "",
    chatMarkupCache: "",
    runDetailsOpenByEventId: {},
    pendingOutgoingByKey: {},
    conversationCacheByKey: {},
    threadsPaneWidth: parseStoredPaneWidth("artificer.threadsPaneWidth", 308),
    diffPaneWidth: 300,
    modelsPaneHeight: parseStoredPaneWidth("artificer.modelsPaneHeight", 300)
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
  var terminalPollTimer = null;
  var terminalPollBusy = false;
  var terminalSessionStartPromise = null;
  var paneDragState = null;
  var pathWidgetClickTimer = null;
  var tooltipEl = null;
  var tooltipTarget = null;
  var tooltipShowTimer = null;
  var tooltipPendingTarget = null;
  var noticeEl = null;
  var noticeHideTimer = null;
  var pendingCommandApproval = null;
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
  if (!/^[a-z0-9_-]+$/.test(String(state.activeTheme || ""))) {
    state.activeTheme = "psionic";
  }
  if (state.commandExecMode !== "none" && state.commandExecMode !== "ask" && state.commandExecMode !== "all") {
    state.commandExecMode = "ask";
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
    agentLoopToggle: document.getElementById("agent-loop-toggle"),
    reasoningMenuBtn: document.getElementById("reasoning-menu-btn"),
    reasoningMenu: document.getElementById("reasoning-menu"),
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
    sshPubOutput: document.getElementById("ssh-pub-output")
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
    "reasoning-menu": el.reasoningMenu,
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

  function showTransientNotice(message) {
    var text = trim(message);
    if (!text) {
      return;
    }
    var node = ensureNoticeEl();
    if (noticeHideTimer) {
      clearTimeout(noticeHideTimer);
      noticeHideTimer = null;
    }
    node.textContent = text;
    node.classList.add("show");
    noticeHideTimer = setTimeout(function () {
      node.classList.remove("show");
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
    var timeoutId = setTimeout(function () {
      controller.abort();
    }, timeoutMs);

    return fetch(url, {
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
      .catch(function (err) {
        if (err && err.name === "AbortError") {
          throw new Error("Request timed out after " + Math.round(timeoutMs / 1000) + "s.");
        }
        throw err;
      })
      .finally(function () {
        clearTimeout(timeoutId);
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
      timeoutMs = 240000;
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
      if (activeStats.pending > 0) {
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
        if (queueNumber(conversations[j].queue_pending) > 0) {
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
    var html = "<span class='conversation-meta' title='Workspace diff since last commit'>";
    if (hasDiff) {
      html += "<span class='meta-add' title='Lines added since last commit'>+" + escHtml(String(add)) + "</span> ";
      html += "<span class='meta-del' title='Lines removed since last commit'>-" + escHtml(String(del)) + "</span> ";
    }
    html += "<span class='meta-age-slot'>";
    html += "<span class='meta-age' title='Conversation age'>" + ((isArchiveArmed || isArchiveSubmitting) ? "" : escHtml(age)) + "</span>";
    html += archiveControlMarkup(workspaceId, conversationId);
    html += "</span></span>";
    return html;
  }

  function archiveControlMarkup(workspaceId, conversationId) {
    var key = conversationReadKey(workspaceId, conversationId);
    var isArmed = key === state.pendingArchiveKey;
    var isSubmitting = key === state.pendingArchiveSubmittingKey;
    if (!isArmed) {
      return (
        "<button type='button' class='thread-archive-btn' title='Archive conversation' data-action='arm-archive-conversation' data-workspace-id='" + escHtml(workspaceId) + "' data-conversation-id='" + escHtml(conversationId) + "'><span class='archive-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'><rect x='2.4' y='3.2' width='11.2' height='9.2' rx='1.4'></rect><path d='M4.5 6.1h7'></path><path d='M6 8.3h4'></path></svg></span></button>"
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
    if (mode === "all") {
      return "All";
    }
    return "Ask me";
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
    if (el.themePickerBtn) {
      el.themePickerBtn.setAttribute("aria-expanded", "false");
    }
    if (el.reasoningMenuBtn) {
      el.reasoningMenuBtn.setAttribute("aria-expanded", "false");
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

  function finalizeLatestRunningEvent(conversationId, status, errorText) {
    var convId = String(conversationId || "");
    if (!convId) {
      return;
    }
    var events = state.runEventsByConversation[convId];
    if (!Array.isArray(events) || !events.length) {
      return;
    }
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") === "running") {
        events[i].status = status === "error" ? "error" : (status === "cancelled" ? "cancelled" : "done");
        events[i].finished_at = new Date().toISOString();
        if (status === "error") {
          events[i].error = trim(errorText || "Run did not complete.");
        }
        return;
      }
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
    var events = state.runEventsByConversation[String(conversation.id || "")];
    if (!Array.isArray(events) || !events.length) {
      return;
    }
    var finishedAt = new Date().toISOString();
    for (var i = events.length - 1; i >= 0; i -= 1) {
      if (String(events[i].status || "") !== "running") {
        continue;
      }
      if (queueStatus === "error") {
        events[i].status = "error";
        if (!trim(events[i].error || "")) {
          events[i].error = "Run did not complete.";
        }
      } else if (queueStatus === "cancelled") {
        events[i].status = "cancelled";
      } else {
        events[i].status = "done";
      }
      events[i].finished_at = finishedAt;
    }
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

  function reconcileRunningState() {
    if (!state.busy || runReconcileBusy) {
      return;
    }
    var workspaceId = String(state.runningWorkspaceId || "");
    var conversationId = String(state.runningConversationId || "");
    if (!workspaceId || !conversationId) {
      return;
    }
    runReconcileBusy = true;
    loadState()
      .then(function () {
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
            return loadConversation().catch(function () {
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
      html += "<pre>" + escHtml(item.output || "") + "</pre>";
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

  function formatRunTrace(event) {
    if (!event) {
      return "";
    }
    var sections = "";
    if (trim(event.stream_text || "")) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Stream Transcript</p><pre>" + escHtml(event.stream_text || "") + "</pre></div>";
    }
    if (trim(event.plan)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Plan</p><pre>" + escHtml(event.plan) + "</pre></div>";
    }
    if (event.commands && event.commands.length) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Command Runs</p>" + formatRunCommands(event.commands || []) + "</div>";
    }
    if (trim(event.git_status || "")) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Git Status</p><pre>" + escHtml(event.git_status || "") + "</pre></div>";
    }
    if (trim(event.git_diff || "")) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Git Diff</p><div class='diff-view run-diff-view'>" + formatDiff(event.git_diff || "") + "</div></div>";
    }
    if (trim(event.state)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Mode State</p><pre>" + escHtml(event.state) + "</pre></div>";
    }
    if (trim(event.failures)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Failure Ledger</p><pre>" + escHtml(event.failures) + "</pre></div>";
    }
    if (trim(event.session_log)) {
      sections += "<div class='run-trace-block'><p class='run-trace-title'>Session Log</p><pre>" + escHtml(event.session_log) + "</pre></div>";
    }
    if (!sections) {
      return "";
    }
    var eventId = String(event.id || "");
    var openAttr = runDetailsShouldBeOpen(eventId) ? " open" : "";
    return "<details class='run-details run-thinking' data-event-id='" + escAttr(eventId) + "'" + openAttr + "><summary>Thinking trace</summary>" + sections + "</details>";
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
    var html = "<article class='msg run " + escHtml(status) + "'>";

    if (status === "running") {
      var startedAt = Date.parse(event.started_at || "");
      var elapsed = 0;
      if (isFinite(startedAt) && startedAt > 0) {
        elapsed = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
      }
      html += "<p class='run-line running' data-started-at='" + escAttr(event.started_at || "") + "'><span class='run-spinner' aria-hidden='true'></span> Thinking";
      html += " <span class='run-elapsed'>" + (elapsed > 0 ? elapsed + "s" : "") + "</span>";
      if (workspaceId && conversationId) {
        html += "<button type='button' class='run-stop-btn' aria-label='Stop run' title='Stop run' data-action='stop-run' data-workspace-id='" + escAttr(workspaceId) + "' data-conversation-id='" + escAttr(conversationId) + "'><span class='run-stop-square' aria-hidden='true'>&#9632;</span></button>";
      }
      html += "</p>";
      var runningEventId = String(event.id || "");
      var streamText = String(event.stream_text || "");
      if (trim(streamText)) {
        var hasSeenToggle = Object.prototype.hasOwnProperty.call(state.runDetailsOpenByEventId, runningEventId);
        var runningOpen = hasSeenToggle ? runDetailsShouldBeOpen(runningEventId) : true;
        var runningOpenAttr = runningOpen ? " open" : "";
        html += "<details class='run-details run-thinking' data-event-id='" + escAttr(runningEventId) + "'" + runningOpenAttr + "><summary>Thinking trace</summary><pre class='run-stream-preview'>" + escHtml(streamText) + "</pre></details>";
      }
      html += "</article>";
      return html;
    }

    if (status === "cancelled") {
      html += "<p class='run-line subtle'>Run stopped.</p>";
      html += formatRunTrace(event);
      html += "</article>";
      return html;
    }

    if (status === "error") {
      html += "<p class='run-line error'>" + escHtml(friendlyRunErrorText(event)) + "</p>";
      html += formatRunTrace(event);
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
    html += "<p class='run-line success'>Run complete" + (runModelText ? " with " + escHtml(runModelText) : "") + "</p>";
    html += formatRunTrace(event);
    html += "</article>";
    return html;
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
      var preview = panel.querySelector(".run-stream-preview");
      if (preview) {
        preview.scrollTop = preview.scrollHeight;
      }
    }
  }

  function renderWorkspaceTree() {
    if (!state.workspaces.length) {
      var emptyMarkup = "<p class='empty-state'>Drop a folder here or click + to add a project.</p>";
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

          html += "<div class='conversation-row chrono-row" + chronoActive + "' role='button' tabindex='0' title='Open conversation' data-action='select-conversation' data-workspace-id='" + escHtml(entry.workspaceId) + "' data-conversation-id='" + escHtml(entry.conversation.id) + "'>";
          html += "<span class='" + chronoIndicatorClass + "' aria-hidden='true'></span>";
          html += "<span class='conversation-title' title='" + escAttr(entry.workspaceName) + "'>" + escHtml(entry.conversation.title || "Conversation") + "</span>";
          html += conversationStatusPillMarkup(entry.workspaceId, entry.conversation, chronoRunning);
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
        html += "<div class='workspace-meta' title='" + escAttr(workspace.path || "") + "'>" + escHtml(workspace.name || "Project") + "</div>";
        html += "<button type='button' class='workspace-new' data-action='new-conversation' data-workspace-id='" + escHtml(workspaceId) + "' aria-label='New conversation' title='New thread'><span aria-hidden='true'><svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'><path d='M3.1 12.9l2.9-.6 6-6-2.3-2.3-6 6z'/><path d='M8.9 3.7l2.3 2.3'/><path d='M13.6 13.1H8.8'/></svg></span></button>";
        html += "<button type='button' class='workspace-menu-trigger' data-action='toggle-workspace-menu' data-workspace-id='" + escHtml(workspaceId) + "' aria-label='Project menu' title='Project actions' aria-expanded='" + (state.openWorkspaceMenuWorkspaceId === workspaceId ? "true" : "false") + "'>&hellip;</button>";
        var workspaceMenuClass = "workspace-actions-pop floating-menu";
        if (state.openWorkspaceMenuWorkspaceId !== workspaceId) {
          workspaceMenuClass += " hidden";
        }
        html += "<div class='" + workspaceMenuClass + "' data-workspace-menu='" + escHtml(workspaceId) + "' role='menu' aria-label='Project actions'>";
        html += "<button type='button' data-action='rename-workspace' data-workspace-id='" + escHtml(workspaceId) + "'>Rename</button>";
        html += "<button type='button' data-action='remove-workspace' data-workspace-id='" + escHtml(workspaceId) + "'>Remove</button>";
        html += "</div>";
        html += "</div>";

        html += "<div class='conversation-shell'>";

        if (hasDraftForWorkspace(workspace)) {
          var draftActive = state.activeDraftWorkspaceId === workspaceId ? " active" : "";
          html += "<button type='button' class='conversation-draft" + draftActive + "' data-action='select-draft' data-workspace-id='" + escHtml(workspaceId) + "'>Draft (unsent)</button>";
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

          html += "<div class='conversation-row" + activeConv + "' role='button' tabindex='0' title='Open conversation' data-action='select-conversation' data-workspace-id='" + escHtml(workspaceId) + "' data-conversation-id='" + escHtml(conversation.id) + "'>";
          html += "<span class='" + indicatorClass + "' aria-hidden='true'></span>";
          html += "<span class='conversation-title'>" + escHtml(conversation.title || "Conversation") + "</span>";
          html += conversationStatusPillMarkup(workspaceId, conversation, queueRunning);
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
    if (!state.models.length) {
      el.modelStatusBtn.textContent = "No models";
      el.modelStatusBtn.title = "No Ollama models detected";
      return;
    }
    var noun = state.models.length === 1 ? "model" : "models";
    el.modelStatusBtn.textContent = state.models.length + " " + noun;
    el.modelStatusBtn.title = state.models.length + " Ollama " + noun + " installed";
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
        var installLabel = isInstalled ? "Installed" : (isInstalling ? "Installing…" : "Install");
        var installDisabled = isInstalled || isInstalling;
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
      html += "<div class='models-section install-log-section'>";
      html += "<p class='models-section-title'>Install log: " + escHtml(jobModel) + " (" + escHtml(jobStatus) + ")</p>";
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

  function renderRunControls() {
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
    if (!el.queueControls || !el.queueSteerBtn || !el.queueCancelBtn) {
      return;
    }

    if (!state.activeWorkspaceId || !state.activeConversationId) {
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
      el.commitMainBtn.disabled = true;
      if (el.commitMenuBtn) {
        el.commitMenuBtn.disabled = true;
      }
      el.changesBtn.innerHTML = gitDeltaMarkup(0, 0);
      return;
    }

    if (!gitState.is_repo) {
      el.branchMenuBtn.textContent = "No repo";
      el.commitMainBtn.disabled = true;
      if (el.commitMenuBtn) {
        el.commitMenuBtn.disabled = true;
      }
      el.changesBtn.innerHTML = gitDeltaMarkup(0, 0);
      return;
    }

    el.branchMenuBtn.textContent = gitState.branch || "Branch";
    el.commitMainBtn.disabled = false;
    if (el.commitMenuBtn) {
      el.commitMenuBtn.disabled = false;
    }
    el.changesBtn.innerHTML = gitDeltaMarkup(gitState.added, gitState.deleted);
  }

  function renderChatHeader() {
    if (!state.activeWorkspaceId) {
      el.chatTitle.textContent = "No conversation";
      return;
    }

    if (state.activeDraftWorkspaceId) {
      el.chatTitle.textContent = "Draft conversation";
      return;
    }

    if (state.activeConversation && state.activeConversation.title) {
      el.chatTitle.textContent = state.activeConversation.title;
      return;
    }

    el.chatTitle.textContent = "No conversation";
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
    if (!request && conversation) {
      var awaitingApproval =
        String(conversation.queue_last_status || "") === "awaiting_approval" ||
        isAwaitingApprovalConversation(state.activeWorkspaceId, state.activeConversationId);
      if (awaitingApproval) {
        request = {
          command: "",
          reason: ""
        };
      }
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

  function submitApprovalRequestAnswer(decision, scope) {
    var info = activeApprovalRequestInfo();
    if (!info) {
      return Promise.resolve();
    }
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
      applyQueueStateFromResponse(info.workspaceId, info.conversationId, response);
      setConversationQueueFields(info.workspaceId, info.conversationId, {
        approvalRequest: null
      });
      if (
        state.activeConversation &&
        state.activeWorkspaceId === info.workspaceId &&
        state.activeConversationId === info.conversationId
      ) {
        state.activeConversation.approval_request = null;
      }
      return loadConversation().catch(function () {
        return null;
      });
    }).then(function () {
      renderUi();
      kickQueueWorker();
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
      return loadConversation().catch(function () {
        return null;
      });
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
    if (pendingCommandApproval) {
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
      submitApprovalRequestAnswer("allow", "once").catch(showError);
    };
    el.commandApprovalInlineDenyOnce.onclick = function () {
      submitApprovalRequestAnswer("deny", "once").catch(showError);
    };
    el.commandApprovalInlineAllowRemember.onclick = function () {
      submitApprovalRequestAnswer("allow", "remember").catch(showError);
    };
    el.commandApprovalInlineDenyRemember.onclick = function () {
      submitApprovalRequestAnswer("deny", "remember").catch(showError);
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
    return "<span class='btn-icon app-icon finder-icon' aria-hidden='true'><svg viewBox='0 0 16 16' fill='none'><rect x='1.2' y='1.2' width='13.6' height='13.6' rx='3.2' fill='#80B6FF' stroke='#4C7CC8' stroke-width='1'></rect><path d='M8 2v12' stroke='#EAF3FF' stroke-width='1'></path><circle cx='5.3' cy='6.2' r='0.8' fill='#0F2A50'></circle><circle cx='10.7' cy='6.2' r='0.8' fill='#0F2A50'></circle><path d='M4.5 10.2c1 .9 2.2 1.4 3.5 1.4s2.5-.5 3.5-1.4' stroke='#0F2A50' stroke-width='1' stroke-linecap='round'></path></svg></span>";
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

  function renderContextWindowStatus() {
    if (!el.contextWindowBtn) {
      return;
    }
    var model = activeModelName();
    if (!model) {
      state.contextWindowText = "Context window information will display here.";
      el.contextWindowBtn.classList.add("unavailable");
      el.contextWindowBtn.setAttribute("data-tooltip", state.contextWindowText);
      return;
    }
    var guess = String(model).match(/(\d+)\s*k/i);
    if (guess && guess[1]) {
      state.contextWindowText = "Context window: estimated " + guess[1] + "k tokens (from model name).";
      el.contextWindowBtn.classList.remove("unavailable");
    } else {
      state.contextWindowText = "No context window information available for this model yet.";
      el.contextWindowBtn.classList.add("unavailable");
    }
    el.contextWindowBtn.setAttribute("data-tooltip", state.contextWindowText);
  }

  function renderChat() {
    var conversationKey = String(state.activeWorkspaceId || "") + "::" + String(state.activeConversationId || "") + "::" + String(state.activeDraftWorkspaceId || "");
    var keyChanged = conversationKey !== state.chatLastKey;
    var prevScrollTop = el.chatLog ? el.chatLog.scrollTop : 0;
    var prevClientHeight = el.chatLog ? el.chatLog.clientHeight : 0;
    var prevScrollHeight = el.chatLog ? el.chatLog.scrollHeight : 0;
    var prevBottomOffset = Math.max(0, prevScrollHeight - prevScrollTop - prevClientHeight);
    var shouldAutoScroll = keyChanged || state.chatAutoScroll;

    if (!state.activeWorkspaceId) {
      var emptyWorkspaceMarkup = "<p class='empty-state'>Select or add a project to begin.</p>";
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
      var draftText = trim(state.draftTextByWorkspace[state.activeDraftWorkspaceId] || "");
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
      } else if (draftText) {
        var draftReadyMarkup = "<p class='empty-state'>Draft loaded. Send your first message to create the conversation.</p>";
        if (state.chatMarkupCache !== draftReadyMarkup) {
          el.chatLog.innerHTML = draftReadyMarkup;
          state.chatMarkupCache = draftReadyMarkup;
        }
      } else {
        var draftEmptyMarkup = "<p class='empty-state'>This is a draft. Start typing below; it autosaves to disk.</p>";
        if (state.chatMarkupCache !== draftEmptyMarkup) {
          el.chatLog.innerHTML = draftEmptyMarkup;
          state.chatMarkupCache = draftEmptyMarkup;
        }
      }
      state.chatAutoScroll = true;
      state.chatLastKey = conversationKey;
      updateChatJumpButton();
      return;
    }

    if (!state.activeConversationId || !state.activeConversation) {
      var noConversationMarkup = "<p class='empty-state'>Select a conversation or click + beside a project to start a draft.</p>";
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
    var events = runEventsForConversation(state.activeConversationId);

    if (!messages.length && !events.length && !pendingOutgoing.length) {
      var noMessagesMarkup = "<p class='empty-state'>No messages yet in this conversation.</p>";
      if (state.chatMarkupCache !== noMessagesMarkup) {
        el.chatLog.innerHTML = noMessagesMarkup;
        state.chatMarkupCache = noMessagesMarkup;
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
    for (var i = 0; i < messages.length; i += 1) {
      var msg = messages[i] || {};
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

    for (var p = 0; p < pendingOutgoing.length; p += 1) {
      var pending = pendingOutgoing[p] || {};
      html += "<article class='msg user pending'><div class='msg-body'>" + escHtml(pending.content || "") + "</div><p class='msg-pending-line'><span class='run-spinner' aria-hidden='true'></span>Sending...</p></article>";
    }

    for (var j = 0; j < events.length; j += 1) {
      html += renderRunEvent(events[j], state.activeWorkspaceId, state.activeConversationId);
    }

    if (state.chatMarkupCache !== html) {
      el.chatLog.innerHTML = html;
      state.chatMarkupCache = html;
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

  function renderDiffView() {
    if (!el.diffView) {
      return;
    }
    var raw = state.diffText || "";
    if (!trim(raw)) {
      el.diffView.innerHTML = "<p class='empty-state'>No diff available.</p>";
      return;
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

    el.diffView.innerHTML = html;
  }

  function renderTerminal() {
    if (!el.terminalOutput) {
      return;
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
    paneDragState = null;
    if (document && document.body) {
      document.body.classList.remove("pane-resizing");
      document.body.classList.remove("pane-resizing-y");
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
    var next = "ask";
    if (mode === "none" || mode === "ask" || mode === "all") {
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
        saveCommandExecMode(response.mode || "ask");
      })
      .catch(function () {
        return null;
      });
  }

  function setCommandExecMode(mode) {
    var next = mode;
    if (next !== "none" && next !== "ask" && next !== "all") {
      next = "ask";
    }
    if (next === "all") {
      var ok = window.confirm("Allow all agent commands without asking? This can run any command the agent proposes.");
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

  function saveReasoningEffort(level) {
    var next = "medium";
    if (level === "low" || level === "medium" || level === "high" || level === "extra-high") {
      next = level;
    }
    state.reasoningEffort = next;
    storageSet("artificer.reasoningEffort", next);
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
    var first = trim(String(promptText || "").split(/\r?\n/)[0] || "");
    if (!first) {
      return "New Conversation";
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

  function loadState() {
    return apiGet("state").then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load state");
      }
      state.workspaces = response.workspaces || [];
      for (var i = 0; i < state.workspaces.length; i += 1) {
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
      bootstrapSeenConversationsIfNeeded();
      pruneSeenConversationState();
      ensureSelection();
      reconcileRunEventsFromQueueState();
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

  function loadConversation() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      state.activeConversation = null;
      return Promise.resolve();
    }

    var workspaceId = state.activeWorkspaceId;
    var conversationId = state.activeConversationId;

    return apiGet("get_conversation", {
      workspace_id: workspaceId,
      conversation_id: conversationId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Failed to load conversation");
      }
      if (state.activeWorkspaceId !== workspaceId || state.activeConversationId !== conversationId) {
        return;
      }
      state.activeConversation = response.conversation;
      state.conversationCacheByKey[conversationReadKey(workspaceId, conversationId)] = cloneConversationData(response.conversation) || response.conversation;
      if (state.activeConversation) {
        state.activeConversation.decision_request = normalizeDecisionRequest(state.activeConversation.decision_request);
        state.activeConversation.approval_request = normalizeApprovalRequest(state.activeConversation.approval_request);
        finalizeStaleRunningEventsForConversation(workspaceId, state.activeConversation);
        reconcilePendingOutgoingFromConversation(workspaceId, conversationId, state.activeConversation);
      }
      markConversationSeen(workspaceId, conversationId, response.conversation);
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
        return modelsPromise;
      })
      .then(function () {
        return modelCatalogPromise;
      })
      .then(function () {
        return appIconsPromise;
      })
      .then(function () {
        return themesPromise;
      })
      .then(function () {
        syncModelInstallPollingFromCatalog();
        modelAutoRefreshLastAt = Date.now();
        state.initialLoadComplete = true;
        renderUi();
      });
  }

  function addWorkspaceByPath(pathText, nameText) {
    var path = trim(pathText);
    var name = trim(nameText);
    if (!path) {
      return Promise.resolve();
    }

    return apiPost("add_workspace", {
      path: path,
      name: name
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
        throw new Error(response.error || "Could not archive conversation");
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
      return Promise.reject(new Error("Workspace is required."));
    }
    if (!name) {
      return Promise.reject(new Error("Workspace name is required."));
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
    state.chatAutoScroll = true;
    state.activeWorkspaceId = workspaceId;
    state.activeConversationId = conversationId;
    var convKey = conversationReadKey(workspaceId, conversationId);
    var cachedConversation = cloneConversationData(state.conversationCacheByKey[convKey]);
    if (!cachedConversation) {
      var workspace = getWorkspaceById(workspaceId);
      var summary = getConversationById(workspace, conversationId);
      if (summary) {
        cachedConversation = {
          id: summary.id,
          title: summary.title || "Conversation",
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
    state.chatAutoScroll = true;
    state.activeWorkspaceId = workspaceId;
    state.activeConversationId = "";
    state.activeConversation = null;
    state.activeDraftWorkspaceId = workspaceId;
    state.openWorkspaceMenuWorkspaceId = "";
    state.expandedWorkspaceIds[workspaceId] = true;

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
        throw new Error(response.error || "Failed to create conversation from draft");
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
    var attachmentList = Array.isArray(runOptions.attachments) ? runOptions.attachments : [];
    var attachmentIds = [];
    var attachmentNames = [];

    if (!workspaceId || !conversationId) {
      return Promise.reject(new Error("Choose a project conversation first."));
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
    if (!pendingEvent) {
      pendingEvent = pushRunEvent(conversationId, {
        status: "running",
        started_at: new Date().toISOString(),
        stream_text: ""
      });
    }

    if (
      !approvalRetry &&
      state.activeWorkspaceId === workspaceId &&
      state.activeConversation &&
      state.activeConversation.id === conversationId
    ) {
      consumePendingOutgoingByText(outgoingKeyFor(workspaceId, conversationId, ""), promptText);
      if (!Array.isArray(state.activeConversation.messages)) {
        state.activeConversation.messages = [];
      }
      var userContent = promptText;
      if (attachmentNames.length) {
        userContent += "\n\nAttached files:\n- " + attachmentNames.join("\n- ");
      }
      state.activeConversation.messages.push({ role: "user", content: userContent });
    }

    renderUi();

    var reasoningToIterations = {
      low: 2,
      medium: 4,
      high: 6,
      "extra-high": 8
    };
    var selectedIterations = reasoningToIterations[state.reasoningEffort] || 2;
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
          streamOffset = Number(response.offset || streamOffset || 0);
          if (delta && pendingEvent) {
            pendingEvent.stream_text = String(pendingEvent.stream_text || "") + delta;
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
      prompt: promptText,
      permission_mode: state.permissionMode,
      command_exec_mode: state.commandExecMode,
      approval_retry: approvalRetry ? "1" : "0",
      network_access: state.networkAccess ? "1" : "0",
      web_access: state.webAccess ? "1" : "0",
      attachment_ids: attachmentIds.join(","),
      queue_item_id: queueItemId,
      advanced_loop: state.agentLoopEnabled ? "1" : "0",
      reasoning_effort: state.reasoningEffort,
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

        var blockedCommands = Array.isArray(response.blocked_commands) ? response.blocked_commands : [];
        if (blockedCommands.length) {
          return handleBlockedCommandsApproval(workspaceId, conversationId, blockedCommands).then(function (approved) {
            if (!approved) {
              throw new Error("Command execution denied.");
            }
            return runAgent(workspaceId, conversationId, promptText, {
              preserveSelection: preserveSelection,
              attachments: attachmentList,
              queueItemId: queueItemId,
              approvalRetry: true,
              pendingEvent: pendingEvent
            });
          });
        }

        if (pendingEvent) {
          pendingEvent.status = "done";
          pendingEvent.model = response.model || "";
          pendingEvent.plan = response.plan || "";
          pendingEvent.commands = response.commands || [];
          pendingEvent.git_status = response.git_status || "";
          pendingEvent.git_diff = response.git_diff || "";
          pendingEvent.state = response.state || "";
          pendingEvent.failures = response.failures || "";
          pendingEvent.session_log = response.session_log || "";
          pendingEvent.finished_at = new Date().toISOString();
        }

        return loadState()
          .then(function () {
            if (!preserveSelection) {
              state.activeWorkspaceId = workspaceId;
              state.activeConversationId = conversationId;
              state.activeDraftWorkspaceId = "";
            }

            if (state.activeWorkspaceId && state.activeConversationId) {
              return loadConversation().catch(function () {
                if (
                  assistantText &&
                  state.activeConversation &&
                  state.activeConversation.id === conversationId
                ) {
                  if (!Array.isArray(state.activeConversation.messages)) {
                    state.activeConversation.messages = [];
                  }
                  var msgs = state.activeConversation.messages;
                  var last = msgs.length ? msgs[msgs.length - 1] : null;
                  if (!last || last.role !== "assistant" || String(last.content || "") !== assistantText) {
                    msgs.push({ role: "assistant", content: assistantText });
                  }
                }
                return null;
              });
            }
            return null;
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
              awaitingDecision: !!decisionRequest,
              awaitingApproval: false
            };
          });
      })
      .catch(function (err) {
        stopStreamPoll();
        setAwaitingApprovalState(workspaceId, conversationId, false);
        if (pendingEvent) {
          pendingEvent.status = "error";
          pendingEvent.error = err && err.message ? err.message : String(err);
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
    if (queueLastStatus === "awaiting_approval") {
      setAwaitingApprovalState(workspaceId, conversationId, true);
    } else if (
      queueLastStatus === "done" ||
      queueLastStatus === "error" ||
      queueLastStatus === "cancelled" ||
      queueLastStatus === "awaiting_decision"
    ) {
      setAwaitingApprovalState(workspaceId, conversationId, false);
    }

    if (pendingCount === 0 && conversationId) {
      delete state.lastQueuedItemIdByConversation[conversationId];
    }

    var workspace = getWorkspaceById(workspaceId);
    var conversation = getConversationById(workspace, conversationId);
    if (conversation) {
      finalizeStaleRunningEventsForConversation(workspaceId, conversation);
    }
  }

  function enqueuePrompt(workspaceId, conversationId, promptText, position, attachmentIds) {
    var attachmentList = Array.isArray(attachmentIds) ? attachmentIds : [];
    return apiPost("queue_enqueue", {
      workspace_id: workspaceId,
      conversation_id: conversationId,
      prompt: promptText,
      position: position || "tail",
      attachments: attachmentList.join(",")
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not queue message");
      }
      applyQueueStateFromResponse(workspaceId, conversationId, response);
      if (response.item_id) {
        state.lastQueuedItemIdByConversation[conversationId] = String(response.item_id);
      }
      return response;
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
      return response;
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

  function startQueueCompletionWatch(workspaceId, conversationId, queueItemId) {
    var active = true;
    var inFlight = false;
    var pollTimer = null;
    var maxWaitMs = 180000;
    var pollFailures = 0;

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
            var conversation = findConversationStateEntry(response, workspaceId, conversationId);
            if (!conversation) {
              return;
            }
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
              decisionRequest: typeof conversation.decision_request === "undefined" ? undefined : conversation.decision_request
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

  function executeQueuedItem(workspaceId, conversationId, queueItem) {
    var item = queueItem || {};
    var itemId = item.id || "";
    var runError = null;
    var runResult = null;
    var finalStatus = "done";
    var finalErrorText = "";
    var queueFinalizeApplied = false;
    var queueWatch = null;

    if (itemId && state.lastQueuedItemIdByConversation[conversationId] === itemId) {
      delete state.lastQueuedItemIdByConversation[conversationId];
    }

    setBusy(true, workspaceId, conversationId);
    setConversationQueueFields(workspaceId, conversationId, {
      running: true,
      done: false,
      lastStatus: "running"
    });
    renderUi();

    queueWatch = startQueueCompletionWatch(workspaceId, conversationId, itemId);

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
        runResult = {
          awaitingDecision: finalStatus === "awaiting_decision",
          awaitingApproval: finalStatus === "awaiting_approval"
        };
      }
      return true;
    }

    return Promise.race([
      runAgent(workspaceId, conversationId, item.prompt || "", {
        preserveSelection: true,
        attachments: Array.isArray(item.attachments) ? item.attachments : [],
        queueItemId: itemId
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
      .then(function () {
        return loadState().catch(function () {
          return null;
        });
      })
      .then(function () {
        if (state.activeWorkspaceId && state.activeConversationId) {
          return loadConversation().catch(function () {
            return null;
          });
        }
        return null;
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
        finalizeLatestRunningEvent(conversationId, finalStatus, finalErrorText);
        setBusy(false);
        renderUi();
      });
  }

  function drainQueuedRuns() {
    if (state.busy) {
      return Promise.resolve();
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

  function steerQueuedMessage() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      return Promise.resolve();
    }
    var queueItemId = trim((el.queueSteerBtn && el.queueSteerBtn.dataset.queueItemId) || "");
    if (!queueItemId) {
      return Promise.resolve();
    }

    return apiPost("queue_steer", {
      workspace_id: state.activeWorkspaceId,
      conversation_id: state.activeConversationId,
      item_id: queueItemId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not steer queued message");
      }
      applyQueueStateFromResponse(state.activeWorkspaceId, state.activeConversationId, response);
      renderUi();
      kickQueueWorker();
    });
  }

  function cancelQueuedMessage() {
    if (!state.activeWorkspaceId || !state.activeConversationId) {
      return Promise.resolve();
    }
    var queueItemId = trim((el.queueCancelBtn && el.queueCancelBtn.dataset.queueItemId) || "");
    if (!queueItemId) {
      return Promise.resolve();
    }

    return apiPost("queue_cancel", {
      workspace_id: state.activeWorkspaceId,
      conversation_id: state.activeConversationId,
      item_id: queueItemId
    }).then(function (response) {
      if (!response.success) {
        throw new Error(response.error || "Could not cancel queued message");
      }
      if (response.item_id && state.lastQueuedItemIdByConversation[state.activeConversationId] === response.item_id) {
        delete state.lastQueuedItemIdByConversation[state.activeConversationId];
      }
      applyQueueStateFromResponse(state.activeWorkspaceId, state.activeConversationId, response);
      renderUi();
      kickQueueWorker();
    });
  }

  function stopConversationRun(workspaceId, conversationId) {
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
          showTransientNotice("Run stopped");
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

  function openSettingsModal() {
    openModal(el.settingsModal);
    loadAuthStatus().catch(showError);
  }

  function handleWorkspaceTreeClick(event) {
    var target = event.target.closest("[data-action]");
    if (!target) {
      return;
    }

    var action = target.getAttribute("data-action");
    var workspaceId = target.getAttribute("data-workspace-id");
    var conversationId = target.getAttribute("data-conversation-id");

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
        createDraftForWorkspace(workspaceId).catch(showError);
      }
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
      renameWorkspace(workspaceId, nextName).catch(showError);
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
      if (!window.confirm("Remove " + label + " and its Artificer conversation history?")) {
        return;
      }
      removeWorkspace(workspaceId).catch(showError);
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
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        selectConversation(workspaceId, conversationId).catch(showError);
      }
      return;
    }

    if (action === "select-draft") {
      if (workspaceId) {
        state.pendingArchiveKey = "";
        state.pendingArchiveReadyAt = 0;
        state.pendingArchiveSubmittingKey = "";
        selectDraft(workspaceId).catch(showError);
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

    var prompt = trim(el.runPrompt.value);
    if (!prompt) {
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

    var queuedPrompt = prompt;
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
          throw new Error("Choose a project conversation first.");
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
          return enqueuePrompt(workspaceId, conversationId, queuedPrompt, "tail", attachmentIds).then(function () {
            resetComposerAttachments();
          });
        }).then(function () {
          state.activeWorkspaceId = workspaceId;
          state.activeConversationId = conversationId;
          state.activeDraftWorkspaceId = "";
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
      showError(new Error("Select a project first."));
      return;
    }

    var includeUnstaged = el.commitIncludeUnstaged.checked ? "1" : "0";
    var message = el.commitMessage.value;
    var nextStep = el.commitNextStep.value === "commit-push" ? "1" : "0";

    apiPost("git_commit", {
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
      })
      .catch(showError);
  }

  function openDiffPanel() {
    state.diffOpen = true;
    refreshDiff().then(renderUi).catch(showError);
  }

  function closeDiffPanel() {
    state.diffOpen = false;
    renderUi();
  }

  function toggleDiffPanel() {
    if (state.diffOpen) {
      closeDiffPanel();
    } else {
      openDiffPanel();
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
      refreshModelData({ force: true, silent: false })
        .then(function () {
          return null;
        })
        .catch(function () {
          renderUi();
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
        startModelInstall(installModel).catch(showError);
        return;
      }
      var button = event.target.closest("button[data-model-name]");
      if (!button) {
        return;
      }
      var modelName = button.getAttribute("data-model-name");
      applyModelSelection(modelName).then(function () {
        closeAllMenus();
        renderUi();
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
      applyModelSelection(modelName)
        .then(function () {
          closeAllMenus();
          renderUi();
        })
        .catch(showError);
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
      onWorkspaceModalSubmit(event).catch(showError);
    });

    on(el.workspaceBrowseBtn, "click", function () {
      onWorkspaceBrowseClick().catch(showError);
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
      onWorkspaceDropped(event).catch(showError);
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
      performOpenTarget(state.lastOpenTarget).catch(showError);
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
          performOpenTarget("finder").catch(showError);
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
        performOpenTarget("finder").catch(showError);
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
      performOpenTarget(target).catch(showError);
    });

    on(el.branchMenuBtn, "click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      refreshBranches().finally(function () {
        renderBranchMenu();
        toggleMenu("branch-menu", el.branchMenuBtn);
      });
    });

    on(el.branchMenuList, "click", function (event) {
      var actionItem = event.target.closest("button[data-branch-action]");
      if (actionItem) {
        var branchAction = actionItem.getAttribute("data-branch-action");
        if (branchAction === "create-repo") {
          createRepoForActiveWorkspace()
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
      apiPost("git_checkout_branch", {
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
        })
        .catch(showError);
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
      apiPost("git_checkout_branch", {
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
        })
        .catch(showError);
    });

    on(el.branchCreateInput, "input", function () {
      if (!el.branchCreateSubmit) {
        return;
      }
      el.branchCreateSubmit.disabled = trim(el.branchCreateInput.value) === "";
    });

    on(el.commitMainBtn, "click", function () {
      performCommitAction(state.lastCommitAction).catch(showError);
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
      performCommitAction(action).catch(showError);
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
      onCommitContinue();
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
        setCommandExecMode(commandMode)
          .then(function () {
            closeAllMenus();
            renderUi();
          })
          .catch(showError);
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
      openTerminal();
      runCommandViaApi(commandText, "run_action")
        .then(function () {
          closeModal(el.runActionModal);
          el.runActionCommand.value = "";
        })
        .catch(showError);
    });

    on(el.settingsBtn, "click", function () {
      openSettingsModal();
    });

    on(el.settingsCloseBtn, "click", function () {
      closeModal(el.settingsModal);
    });

    on(el.settingsModal, "click", function (event) {
      if (event.target === el.settingsModal) {
        closeModal(el.settingsModal);
      }
    });

    on(el.refreshAuthBtn, "click", function () {
      loadAuthStatus().catch(showError);
    });

    if (el.githubUsername) {
      on(el.githubUsername, "input", function () {
        state.githubUsername = trim(el.githubUsername.value);
        storageSet("artificer.githubUsername", state.githubUsername);
      });
    }

    on(el.generateSshBtn, "click", function () {
      apiPost("git_generate_ssh", { email: trim(el.sshEmail.value) })
        .then(function (response) {
          if (!response.success) {
            throw new Error(response.error || "Could not generate SSH key");
          }
          el.sshPubOutput.value = response.ssh_pub_key || "";
          el.sshKeyStatus.textContent = "SSH key ready";
        })
        .catch(showError);
    });

    if (el.chooseSshBtn) {
      on(el.chooseSshBtn, "click", function () {
        apiPost("git_choose_ssh_key", {})
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
          })
          .catch(showError);
      });
    }

    if (el.clearSshBtn) {
      on(el.clearSshBtn, "click", function () {
        apiPost("git_clear_ssh_key", {})
          .then(function (response) {
            if (!response.success) {
              throw new Error(response.error || "Could not clear SSH key selection");
            }
            return loadAuthStatus();
          })
          .catch(showError);
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
      toggleDiffPanel();
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
      submitDecisionRequest().catch(showError);
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
      var stopBtn = event.target.closest("[data-action='stop-run'][data-workspace-id][data-conversation-id]");
      if (stopBtn) {
        event.preventDefault();
        var stopWorkspaceId = stopBtn.getAttribute("data-workspace-id") || "";
        var stopConversationId = stopBtn.getAttribute("data-conversation-id") || "";
        stopBtn.disabled = true;
        stopConversationRun(stopWorkspaceId, stopConversationId).catch(showError).finally(function () {
          stopBtn.disabled = false;
        });
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
          var preview = panel.querySelector(".run-stream-preview");
          if (preview) {
            preview.scrollTop = preview.scrollHeight;
          }
        }
      }, true);
    }

    on(el.chatLog, "scroll", function () {
      state.chatAutoScroll = isChatAtBottom();
      updateChatJumpButton();
    });

    on(el.chatJumpBottomBtn, "click", function () {
      jumpChatToBottom();
    });

    if (el.queueSteerBtn) {
      on(el.queueSteerBtn, "click", function () {
        steerQueuedMessage().catch(showError);
      });
    }

    if (el.queueCancelBtn) {
      on(el.queueCancelBtn, "click", function () {
        cancelQueuedMessage().catch(showError);
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
        event.target.closest("[data-workspace-menu]")
      ) {
        return;
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
    clearPendingAttachments();
  });

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
      if (typeof window !== "undefined") {
        window.__artificerBooted = true;
      }
    })
    .catch(function (error) {
      state.initialLoadComplete = true;
      showError(error);
    });
})();
