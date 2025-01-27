// Loads all Semantic javascripts
//= require semantic-ui

const github_endpoints = {
  get_repos: '/github_integration/get_repositories',
  get_branches: '/github_integration/get_branches',
  get_commits: '/github_integration/get_commits',
}

function update_repos() {
  $.getJSON(github_endpoints['get_repos'], function(data, status) {
    repos_html = "";
    data.forEach(repo => {
      repos_html += `<div class="item">${repo["repo_name"]}</div>`;
    });
    $("#repo-dropdown .menu").html(repos_html);
  });
}

function clear_branches() {
  $("#branch-dropdown input[name='branch']").addClass("noselection");
  $("#branch-dropdown .text").addClass("default");
  $("#branch-dropdown .text").text("Select branch");
  $("#branch-dropdown .menu").html("");
}

function clear_commits() {
  $("#commit-dropdown input[name='commit']").addClass("noselection");
  $("#commit-dropdown .text").addClass("default");
  $("#commit-dropdown .text").text("Select commit");
  $("#commit-dropdown .menu").html("");
}

function update_branches(repo) {
  clear_branches();
  clear_commits();
  $.getJSON(github_endpoints['get_branches'], {repository: repo}, function(data, status) {
    branches_html = "";
    data.forEach(branch => {
      branches_html += `<div class="item">${branch["name"]}</div>`;
    });
    $("#branch-dropdown .menu").html(branches_html);
  });
}

function update_commits(repo, branch) {
  clear_commits();
  $.getJSON(github_endpoints['get_commits'], {repository: repo, branch: branch}, function(data, status) {
    commits_html = "";
    data.forEach(commit => {
      commits_html += `<div data-value="${commit["sha"]}" class="item">${commit["sha"]} (${commit["msg"]})</div>`;
    });
    $("#commit-dropdown .menu").html(commits_html);
  });
}

$("a[data-tab=github]").click(function (e) {
  update_repos();
});

$(function () {
  // On page load, update the repos if you're on the github submission tab
  if (on_github_submission_tab()) {
    update_repos();
  }
});

function update_repo_name(new_repo_name) {
  update_branches(new_repo_name);
}

$("#repo-dropdown").change(function() {
  const repo_name = $("#repo-dropdown input[name='repo']").val();
  update_repo_name(repo_name);
});

$("#branch-dropdown").change(function() {
  const repo_name = $("#repo-dropdown input[name='repo']").val();
  const branch_name = $("#branch-dropdown input[name='branch']").val();
  update_commits(repo_name, branch_name);
});

// https://stackoverflow.com/questions/5524045/jquery-non-ajax-post
function submit(action, method, input) {
  'use strict';
  let form;
  form = $('<form />', {
      action: action,
      method: method,
      style: 'display: none;'
  });
  if (typeof input !== 'undefined' && input !== null) {
      $.each(input, function (name, value) {
          $('<input />', {
              type: 'hidden',
              name: name,
              value: value
          }).appendTo(form);
      });
  }
  form.appendTo('body').submit();
}

function on_github_submission_tab() {
  // Returns true if you're currently on the Github submission tab
  const tab = $(".submission-panel .ui.tab.active").attr('id');
  return (tab === "github_tab" && !$(this).is(":disabled"));
}

$(document).on("click", "input[type='submit']", function (e) {
  if (on_github_submission_tab()) {
    e.preventDefault();
    const repo_name = $("#repo-dropdown input[name='repo']").val();
    const branch_name = $("#branch-dropdown input[name='branch']").val();
    const commit_sha = $("#commit-dropdown input[name='commit']").val();
    const token = $("meta[name=csrf-token]").attr("content");
    const params = {
      repo: repo_name, branch: branch_name, commit: commit_sha, authenticity_token: token, github_submission: true
    };
    const url = window.location.pathname + "/handin";
    submit(url, 'post', params);
  }
});

$(document).ready(function () {
  $('.ui.dropdown input[type="hidden"]').val("");
  $('.ui.dropdown').dropdown({
    fullTextSearch: true,
  });
  $('.ui.dropdown#repo-dropdown').dropdown({
    // Allow manually specifying a repo name
    fullTextSearch: true,
    allowAdditions: true,
    hideAdditions: false,
  });
});
