#!/usr/bin/env python

import fnmatch
import os
import sys

try:
    import github3
except ImportError:
    github3 = None


ERR = 1

ENV_TOKEN = 'GITHUB_TOKEN'
ENV_USER = 'GITHUB_USER'
ENV_PASS = 'GITHUB_PASS'


class BadGithubRepo(Exception):
    pass


def two_fa():
    code = ''
    while not code:
        code = raw_input('Enter Github 2FA Code: ')

    return code


class RequirementsAnalyzer(object):
    SPECIFIERS = ['==', '!=' '<=', '>=', '<', '>']

    def __init__(self, remote, local, patterns=['requirements.txt'], verbose=False):
        self.api = None
        self.remote_sources = remote
        self.local_sources = local
        self.req_patterns = patterns
        self.verbose = verbose

        if github3:
            if os.environ.get(ENV_TOKEN):
                self.api = github3.login(
                    token=os.environ.get(ENV_TOKEN)
                )
            elif os.environ.get(ENV_USER) and os.environ.get(ENV_PASS):
                self.api = github3.login(
                    os.environ.get(ENV_USER),
                    os.environ(ENV_PASS),
                    two_factor_callback=two_fa
                )

    def get_repo_requirements(self, repo):
        reqs = {}

        _repo = repo.split('/')
        if len(_repo) is not 2:
            raise BadGithubRepo

        org = _repo[0]
        repository = _repo[1]
        gh_repo = self.api.repository(org, repository)

        contents = gh_repo.directory_contents('/', return_as=dict)
        files = {}
        for entry, content in contents.iteritems():
            if content.type != "dir":
                files[content.name] = content
                continue

            req = gh_repo.file_contents("/{}/requirements.txt".format(entry))
            reqs[entry] = req.decoded

        fmatches = []
        for pattern in self.req_patterns:
            fmatches.extend(fnmatch.filter(files.keys(), pattern))

        for match in fmatches:
            req = gh_repo.file_contents(files[match].path)
            reqs[match] = req.decoded

        return reqs

    def get_local_files(self):
        matches = []
        for src in self.local_sources:
            for pattern in self.req_patterns:
                for root, dirnames, filenames in os.walk(src):
                    for filename in fnmatch.filter(filenames, pattern):
                        matches.append(os.path.join(root, filename))

        return matches

    def get_local_contents(self, files):
        local_reqs = {}
        for fname in files:
            with open(fname) as f:
                content = f.read()

            local_reqs[fname] = content

        return local_reqs

    def get_all_requirements(self):
        reqs = {}
        if self.api:
            for repo in self.remote_sources:
                try:
                    requirements = self.get_repo_requirements(repo)
                    if requirements:
                        reqs[repo] = requirements
                except BadGithubRepo:
                    print 'Unable to get repo requirements for {} - skipping.'.format(repo)
        else:
            print 'No Github API set (missing creds?) cant crawl remotes.'

        for local in self.local_sources:
            requirements = self.get_local_contents(self.get_local_files())
            reqs[local] = requirements

        return reqs

    def process_requirements(self, sources):
        err = 0
        reqs = {}

        for source, requirements in sources.iteritems():
            for integration, content in requirements.iteritems():
                if self.verbose:
                    print "processing... {}/{}".format(source, integration)
                mycontent = content.splitlines()

                for line in mycontent:
                    line = "".join(line.split())
                    for specifier in self.SPECIFIERS:
                        idx = line.find(specifier)
                        if idx < 0:
                            continue

                        req = line[:idx]
                        specifier = line[idx:]

                        if req in reqs and reqs[req][0] != specifier:
                            # version mismatch
                            print "There's a version mismatch with {req} " \
                                " {spec} and {prev_spec} defined in {src} " \
                                "@ {repo}.".format(
                                    req=req,
                                    spec=specifier,
                                    prev_spec=reqs[req][0],
                                    src=reqs[req][1],
                                    repo=reqs[req][2]
                                )
                            err = ERR
                            break
                        elif req not in reqs:
                            reqs[req] = (specifier, integration, source)
                            break

        return err, reqs


def str2bool(v):
    return v.lower() in ("yes", "true", "t", "1")

def main(args):
    remote = local = []
    verbose = str2bool(os.environ.get('VERBOSE', 'false'))
    if not len(args):
        remote = [repo.strip() for repo in os.environ.get('REQ_REMOTES', '').split(',')]
        local = [repo.strip() for repo in os.environ.get('REQ_LOCALS', '').split(',')]
    elif len(args) == 1:
        local = [repo.strip() for repo in args[0].split(',')]
    elif len(args) == 2:
        local = [repo.strip() for repo in args[0].split(',')]
        remote = [repo.strip() for repo in args[1].split(',')]
    else:
        local = ['.']

    analyzer = RequirementsAnalyzer(
        remote=remote, local=local, patterns=['requirements*.txt'], verbose=verbose)

    err, reqs = analyzer.process_requirements(analyzer.get_all_requirements())
    if not err:
        print "No requirement version conflicts found. Looking good... ;)"
        if verbose:
            for requirement, spec in reqs.iteritems():
                print "{req}{spec} first found in {fname} @ {source}".format(
                    req=requirement,
                    spec=spec[0],
                    fname=spec[1],
                    source=spec[2]
                )

    sys.exit(err)

if __name__ == "__main__":
    main(sys.argv[1:])
