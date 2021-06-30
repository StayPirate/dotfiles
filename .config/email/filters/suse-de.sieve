# Sieve: https://tools.ietf.org/html/rfc5228
require ["fileinto", "body", "variables"];

set "susede_email" "ggabrielli@suse.de";
set "susecom_email" "gianluca.gabrielli@suse.com";

# rule:[SPAM]
if allof ( header :contains "X-Spam-Flag" "YES",
           # Whitelist very important ML from where I cannot risk losing emails in the SPAM folder.
           not anyof ( header  :is "X-List" "vs.openwall.org",
                       address :is "From" "cert+donotreply@cert.org" )) {
    fileinto "INBOX/Spam";
    stop;
}


######################
#####  Bugzilla  #####
######################
# Tools
# └── Bugzilla
#     ├── Direct
#     └── Security Team
#         ├── Embargoed
#         └── Reassigned back

# rule:[BZ - mute bots]
# Do not allow bots to make noise to specific Bugzilla's sub-folder,
# put them into the generic Bugzilla folder instead.
if allof ( address :is "From" "bugzilla_noreply@suse.com",
           anyof ( header :is "X-Bugzilla-Who" "swamp@suse.de",
                   header :is "X-Bugzilla-Who" "bwiedemann+obsbugzillabot@suse.com",
                   header :is "X-Bugzilla-Who" "smash_bz@suse.de",
                   header :is "x-bugzilla-who" "maint-coord+maintenance_robot@suse.de",
                   header :is "x-bugzilla-who" "openqa-review@suse.de" )) {
	discard;
	stop;
}

# rule:[BZ - CC me]
# Added or removed from CC into a bugzilla security issue.
# Put it into the Direct folder.
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           address :is "To" "security-team@suse.de",
           header  :is "X-Bugzilla-Type" "changed",
           header  :is "X-Bugzilla-Changed-Fields" "cc",
           body    :contains "|${susecom_email}" ) {
    fileinto "INBOX/Tools/Bugzilla/Direct";
    stop;
}

# rule:[BZ - mute new (not me) CC ]
# Ignore, if the only change is a new person added/removed to CC.
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           header  :is "X-Bugzilla-Type" "changed",
           header  :is "X-Bugzilla-Changed-Fields" "cc" ) {
    discard;
    stop;
}

# rule:[BZ - direct notification]
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           address :is "To" "${susecom_email}" ) {
    fileinto "INBOX/Tools/Bugzilla/Direct";
    stop;
}

# rule:[BZ - Embargoed notification]
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           address :is "To" "security-team@suse.djira@suse.come",
           header  :contains "Subject" "EMBARGOED" ) {
    fileinto "INBOX/Tools/Bugzilla/Security Team/Embargoed";
    stop;
}

# rule:[BZ - No Longer Embargoed]
# Embargoed issues when become public
if allof ( address    :is "From" "bugzilla_noreply@suse.com", 
           address    :is "To" "security-team@suse.de",
           header     :is "X-Bugzilla-Type" "changed",
           header     :contains "X-Bugzilla-Changed-Fields" "short_desc",
           not header :contains "Subject" "EMBARGOED",
           body       :contains "EMBARGOED" ) {
    fileinto "INBOX/Tools/Bugzilla/Security Team/Embargoed";
    stop;
}

# rule:[BZ - maint-coord - catch all]
# All the issues assigned to maint-coord go to the not monitored Maintenance folder
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           address :is "To" "maint-coord@suse.de" ) {
    discard;
    stop;
}

# rule:[BZ - security - reassigned]
# Issues re-assigned to security-team
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           header  :is "x-bugzilla-assigned-to" "security-team@suse.de",
           header  :is "X-Bugzilla-Type" "changed",
           header  :contains "x-bugzilla-changed-fields" "assigned_to" ) {
    fileinto "INBOX/Tools/Bugzilla/Security Team/Reassigned back";
    stop;
}

# rule:[BZ - security]
# Notifications sent to security-team, no bot's messages end up here.
if allof ( address :is "From" "bugzilla_noreply@suse.com", 
           address :is "To" "security-team@suse.de" ) {
    fileinto "INBOX/Tools/Bugzilla/Security Team";
    stop;
}


#######################
#####    I B S    #####
#######################
# Tools
# └── IBS
#     ├── build
#     └── requests
#         ├── pushed back
#         └── to review

# rule:[IBS - mute bots]
# Delete noisy bot comments
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.suse.de",
           anyof ( header :is "x-obs-event-type" "comment_for_request",
                   header :is "x-obs-event-type" "comment_for_project" ),
           anyof ( header :is "x-obs-request-commenter" "sle-qam-openqa",
                   header :is "x-obs-request-commenter" "maintenance-robot",
                   header :is "x-obs-request-commenter" "openqa-maintenance",
                   header :is "x-obs-request-commenter" "abichecker",
                   header :is "x-obs-request-commenter" "cloud_bot" )) {
    discard;
    stop;
}

# rule:[IBS - ignore maintenance-team review requested]
# IBS ignore reviews for the maintenance-team
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.suse.de",
           header :is "x-obs-event-type" "review_wanted",
           header :is "x-obs-review-by-group" "maintenance-team" ) {
    discard;
    stop;
}

# rule:[IBS - security-team review requested]
# A review is pending for the security-team
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.suse.de",
           header :is "x-obs-event-type" "review_wanted",
           header :is "x-obs-review-by-group" "security-team" ) {
    fileinto "INBOX/Tools/IBS/requests/to review";
    stop;
}

# rule:[IBS - my request declined]
# A request issued by me is not accepted
if allof (     header :is "X-Mailer" "OBS Notification System",
               header :is "X-OBS-URL" "https://build.suse.de",
               header :is "x-obs-request-creator" "crazybyte",
               header :is "x-obs-event-type" "request_statechange",
           not header :is "x-obs-request-state" "accepted" ) {
    fileinto "INBOX/Tools/IBS/requests/pushed back";
    stop;
}

# rule:[IBS - my build failed]
# A package I maintain failed to build
if allof ( header  :is "X-Mailer" "OBS Notification System",
           header  :is "X-OBS-URL" "https://build.suse.de",
           address :contains "To" "${susecom_email}",
           header  :contains "x-obs-event-type" "build_fail" ) {
    fileinto "INBOX/Tools/IBS/build";
    stop;
}

# rule:[IBS - my request]
# Notification for requests I issued
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.suse.de",
           header :is "x-obs-request-creator" "crazybyte" ) {
    fileinto "INBOX/Tools/IBS/requests";
    stop;
}

# rule:[IBS - catch all]
# Any other notification from IBS goes into the generic IBS folder
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.suse.de" ) {
    fileinto "INBOX/Tools/IBS";
    stop;
}


#######################
#####    O B S    #####
#######################
# Tools
# └── OBS
#     ├── build
#     └── Security Tools

# rule:[OBS - mute bots]
# Delete noisy bot comments
if allof ( header :is "x-mailer" "OBS Notification System",
           header :is "x-obs-url" "https://build.opensuse.org",
           anyof ( header :is "x-obs-event-type" "comment_for_request",
                   header :is "x-obs-event-type" "comment_for_project" ),
           anyof ( header :is "x-obs-request-commenter" "sle-qam-openqa",
                   header :is "x-obs-request-commenter" "maintenance-robot",
                   header :is "x-obs-request-commenter" "openqa-maintenance",
                   header :is "x-obs-request-commenter" "abichecker" )) {
    discard;
    stop;
}

# rule:[OBS - security tools]
if allof ( header  :is "X-Mailer" "OBS Notification System",
           header  :is "X-OBS-URL" "https://build.opensuse.org",
           address :is "To" "security-team@suse.de" ) {
    fileinto "INBOX/Tools/OBS/Security tools";
    stop;
}

# rule:[OBS - my build failed]
# A package I maintain failed to build
if allof ( header  :is "X-Mailer" "OBS Notification System",
           header  :is "X-OBS-URL" "https://build.opensuse.org",
           address :contains "To" "${susecom_email}",
           header  :contains "x-obs-event-type" "build_fail" ) {
    fileinto "INBOX/Tools/OBS/build";
    stop;
}

# rule:[OBS - catch all]
# Any other notification from OBS goes into the generic OBS folder
if allof ( header :is "X-Mailer" "OBS Notification System",
           header :is "X-OBS-URL" "https://build.opensuse.org" ) {
    fileinto "INBOX/Tools/OBS";
    stop;
}


#######################
#####   J I R A   #####
#######################
# Tools
# └── Jira

# rule:[Jira - catch all]
# Notifications from Jira end up here.
if allof ( address :is "From" "jira@suse.com" ) {
    fileinto "INBOX/Tools/Jira";
    stop;
}


########################
#####  CONFLUENCE  #####
########################
# Tools
# └── Confluence

# rule:[Confl - catch all]
# Notifications from Confluence end up here.
if allof ( address :is "From" "confluence@suse.com" ) {
    fileinto "INBOX/Tools/Confluence";
    stop;
}


#######################
##### G I T L A B #####
#######################
# Tools
# └── Gitlab

# rule:[Gitlab - catch all]
# Notifications from Gitlab end up here.
if allof ( address :is "From" "gitlab@suse.de" ) {
    fileinto "INBOX/Tools/Gitlab";
    stop;
}


#######################
##### Internal ML #####
#######################
### SUSEDE: https://mailman.suse.de/mailman/listinfo
### SUSECOM: http://lists.suse.com/mailman/listinfo
#
# ML
# └── SUSE
#     ├── security-team
#     ├── security
#     │   ├── Xen Security Advisory
#     │   ├── MariaDB
#     │   ├── Django
#     │   └── Ceph
#     ├── maintsecteam
#     ├── security-reports
#     │   └── Embargo Alerts
#     ├── devel
#     ├── high-impact-vul
#     ├── high-impact-vul-info
#     ├── kernel
#     ├── linux
#     ├── maint-coord
#     ├── maintsec-reports
#     │   └── channels changes
#     ├── research
#     ├── results
#     ├── secure-boot
#     ├── secure-devel
#     ├── security-intern
#     ├── security-review
#     ├── sle-security-updates
#     │   ├── container
#     │   └── image
#     └── users

# rule:[SUSEDE - devel]
# https://mailman.suse.de/mailman/listinfo/devel
if header :contains "List-Id" "<devel.suse.de>" { fileinto "INBOX/ML/SUSE/devel"; stop; }

# rule:[SUSEDE - high-impact-vul]
# https://mailman.suse.de/mailman/listinfo/high-impact-vul
if header :contains "List-Id" "<high-impact-vul.suse.de>" { fileinto "INBOX/ML/SUSE/high-impact-vul"; stop; }

# rule:[SUSEDE - high-impact-vul-info]
# https://mailman.suse.de/mailman/listinfo/high-impact-vul-info
if header :contains "List-Id" "<high-impact-vul-info.suse.de>" { fileinto "INBOX/ML/SUSE/high-impact-vul-info"; stop; }

# rule:[SUSEDE - kernel]
# https://mailman.suse.de/mailman/listinfo/kernel
if header :contains "List-Id" "<kernel.suse.de>" { fileinto "INBOX/ML/SUSE/kernel"; stop; }

# rule:[SUSEDE - maintsecteam]
# https://mailman.suse.de/mailman/listinfo/maintsecteam
if header :contains "List-Id" "<maintsecteam.suse.de>" { fileinto "INBOX/ML/SUSE/maintsecteam"; stop; }

# rule:[SUSEDE - maintsec-reports - channel file changed]
if allof ( header :contains "List-Id" "<maintsec-reports.suse.de>",
           header :contains "Subject" "Channel changes for" ) {
    fileinto "INBOX/ML/SUSE/maintsec-reports/channels changes";
    stop;
}
# rule:[SUSEDE - maintsec-reports]
# https://mailman.suse.de/mailman/listinfo/maintsec-reports
if header :contains "List-Id" "<maintsec-reports.suse.de>" { fileinto "INBOX/ML/SUSE/maintsec-reports"; stop; }

# rule:[SUSEDE - maint-coord]
# https://mailman.suse.de/mailman/listinfo/maint-coord
if header :contains "List-Id" "<maint-coord.suse.de>" { fileinto "INBOX/ML/SUSE/maint-coord"; stop; }

# rule:[SUSEDE - research]
# https://mailman.suse.de/mailman/listinfo/research
if header :contains "List-Id" "<research.suse.de>" { fileinto "INBOX/ML/SUSE/research"; stop; }

# rule:[SUSEDE - results]
# https://mailman.suse.de/mailman/listinfo/results
if header :contains "List-Id" "<results.suse.de>" { fileinto "INBOX/ML/SUSE/results"; stop; }

# rule:[SUSEDE - secure-boot]
# https://mailman.suse.de/mailman/listinfo/secure-boot
if header :contains "List-Id" "<secure-boot.suse.de>" { fileinto "INBOX/ML/SUSE/secure-boot"; stop; }

# rule:[SUSEDE - secure-devel]
# https://mailman.suse.de/mailman/listinfo/secure-devel
if header :contains "List-Id" "<secure-devel.suse.de>" { fileinto "INBOX/ML/SUSE/secure-devel"; stop; }

# rule:[SUSEDE - security - xen]
if allof ( header :contains "List-Id" "<security.suse.de>",
           address :is "From" "security@xen.org" ) {
    fileinto "INBOX/ML/SUSE/security/Xen Security Advisory";
    stop;
}
# rule:[SUSEDE - security - chep redhat noise]
# Remove all the noise made by the RH secalert
if allof ( header  :contains "List-Id" "<security.suse.de>",
           address :contains "To" "security@ceph.io",
           anyof ( address :is "From" "secalert@redhat.com",
                   address :is "From" "infosec@redhat.com" )) {
    discard;
    stop;
}
# rule:[SUSEDE - security - chep]
if allof ( header :contains "List-Id" "<security.suse.de>",
           anyof ( address :is "CC" "security@ceph.io",
                   address :is "To" "security@ceph.io" )) {
    fileinto "INBOX/ML/SUSE/security/Ceph";
    stop;
}
# rule:[SUSEDE - security - MariaDB]
if allof ( header  :contains "List-Id" "<security.suse.de>",
           address :is "From" "announce@mariadb.org") {
    fileinto "INBOX/ML/SUSE/security/MariaDB";
    stop;
}
# rule:[SUSEDE - security - Django]
if allof ( header :contains "List-Id" "<security.suse.de>",
           header :contains "Subject" "Django security releases") {
    fileinto "INBOX/ML/SUSE/security/Django";
    stop;
}
# rule:[SUSEDE - security]
# https://mailman.suse.de/mailman/listinfo/security
if header :contains "List-Id" "<security.suse.de>" { fileinto "INBOX/ML/SUSE/security"; stop; }

# rule:[SUSEDE - security-intern]
# https://mailman.suse.de/mailman/listinfo/security-intern
if header :contains "List-Id" "<security-intern.suse.de>" { fileinto "INBOX/ML/SUSE/security-intern"; stop; }

# rule:[SUSEDE - security-reports - Embargo Alerts]
if allof ( header :contains "List-Id" "<security-reports.suse.de>",
           header :contains "Subject" "EMBARGOED ISSUE MENTIONED IN" ) {
    fileinto "INBOX/ML/SUSE/security-reports/Embargo Alerts"; 
    stop;
}
# rule:[SUSEDE - security-reports - Embargo date missing]
if allof ( header :contains "List-Id" "<security-reports.suse.de>",
           header :contains "Subject" "OBS:EmbargoDate not set for" ) {
    fileinto "INBOX/ML/SUSE/security-reports/Embargo Alerts"; 
    stop;
}
# rule:[SUSEDE - security-reports]
# https://mailman.suse.de/mailman/listinfo/security-reports
if header :contains "List-Id" "<security-reports.suse.de>" { fileinto "INBOX/ML/SUSE/security-reports"; stop; }

# rule:[SUSEDE - security-review]
# https://mailman.suse.de/mailman/listinfo/security-review
if header :contains "List-Id" "<security-review.suse.de>" { fileinto "INBOX/ML/SUSE/security-review"; stop; }

# rule:[SUSEDE - security-team - security-team and me in CC ]
# When someone follows up on a thread where I'm also in CC, I want it in the same ML folder
if allof (     address :contains "CC" "security-team@suse.de",
               address :contains "CC" "ggabrielli@suse.de",
           not address :contains "To" "ggabrielli@suse.de" ) {
    fileinto "INBOX/ML/SUSE/security-team";
    stop;
}
# rule:[SUSEDE - security-team]
# https://mailman.suse.de/mailman/listinfo/security-team
if header :contains "List-Id" "<security-team.suse.de>" { fileinto "INBOX/ML/SUSE/security-team"; stop; }

# rule:[SUSEDE - users]
# https://mailman.suse.de/mailman/listinfo/users
if header :contains "List-Id" "<users.suse.de>" { fileinto "INBOX/ML/SUSE/users"; stop; }

# rule:[SUSECOM - linux]
# http://lists.suse.com/mailman/listinfo/linux
if header :contains "List-Id" "<linux.lists.suse.com>" { fileinto "INBOX/ML/SUSE/linux"; stop; }

# rule:[SUSECOM - sle-security-updates - containers]
if allof ( header :contains "List-Id" "<sle-security-updates.lists.suse.com>",
           body :contains "SUSE Container Update Advisory" ) {
    fileinto "INBOX/ML/SUSE/sle-security-updates/container"; 
    stop;
}
# rule:[SUSECOM - sle-security-updates - images]
if allof ( header :contains "List-Id" "<sle-security-updates.lists.suse.com>",
           body :contains "SUSE Image Update Advisory" ) {
    fileinto "INBOX/ML/SUSE/sle-security-updates/image"; 
    stop;
}
# rule:[SUSECOM - sle-security-updates]
# https://lists.suse.com/mailman/listinfo/sle-security-updates
if header :contains "List-Id" "<sle-security-updates.lists.suse.com>" { fileinto "INBOX/ML/SUSE/sle-security-updates"; stop; }


#######################
##### External ML #####
#######################
### OpenSUSE: https://lists.opensuse.org
### Seclist: https://seclists.org/
### Open Source Security Foundation: https://lists.openssf.org/g/mas
#
# ML
# ├── OpenSUSE
# │   ├── factory
# │   ├── users
# │   └── security announce
# ├── SecList
# │   ├── Nmap Announce
# │   ├── Breach Exchange
# │   ├── Full Disclosure
# │   │   ├── malvuln
# │   │   ├── apple
# │   │   ├── korelogic
# │   │   ├── onapsis
# │   │   ├── asterisk
# │   │   └── mikrotik
# │   ├── Open Source Security
# │   ├── linux-distro
# │   ├── vince
# │   ├── Info Security News
# │   ├── CERT Advisories
# │   └── OpenSSF
# │       ├── Announcements
# │       ├── Security Threats
# │       ├── Security Tooling
# │       ├── Vul Disclosure
# │       └── Code Best Practices
# ├── Debian
# │   ├── Security Announce
# │   └── Security Tracker
# └── Security News
#     └── LWN

# rule:[OpenSUSE - factory]
# https://lists.opensuse.org/archives/list/factory@lists.opensuse.org/
if header :contains "List-Id" "<factory.lists.opensuse.org>" { fileinto "INBOX/ML/OpenSUSE/factory"; stop; }

# rule:[OpenSUSE - users]
# https://lists.opensuse.org/archives/list/users@lists.opensuse.org/
if header :contains "List-Id" "<users.lists.opensuse.org>" { fileinto "INBOX/ML/OpenSUSE/users"; stop; }

# rule:[OpenSUSE - security-announce]
# https://lists.opensuse.org/archives/list/security-announce@lists.opensuse.org/
if header :contains "List-Id" "<security-announce.lists.opensuse.org>" { fileinto "INBOX/ML/OpenSUSE/security announce"; stop; }

# rule:[Seclist - nmap announce]
# https://nmap.org/mailman/listinfo/announce
if header :contains "List-Id" "<announce.nmap.org>" { fileinto "INBOX/ML/SecList/Nmap Announce"; stop; }

# rule:[Seclist - breachexchang]
# https://www.riskbasedsecurity.com/mailing-list/
if header :contains "List-Id" "<breachexchange.lists.riskbasedsecurity.com>" { fileinto "INBOX/ML/SecList/Breach Exchange"; stop; }

# rule:[Seclist - Full-Disclosure - malvuln]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           address :is "From" "malvuln13@gmail.com" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/malvuln"; 
    stop;
}
# rule:[Seclist - Full-Disclosure - apple-sa]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           address :is "To" "security-announce@lists.apple.com" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/apple"; 
    stop;
}
# rule:[Seclist - Full-Disclosure - korelogic-sa]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           address :is "Reply-To" "disclosures@korelogic.com" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/korelogic"; 
    stop;
}
# rule:[Seclist - Full-Disclosure - korelogic-sa]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           address :is "Reply-To" "research@onapsis.com" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/onapsis"; 
    stop;
}
# rule:[Seclist - Full-Disclosure - asterisk-sa]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           address :is "From" "security@asterisk.org" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/asterisk"; 
    stop;
}
# rule:[Seclist - Full-Disclosure - mikrotik-sa]
if allof ( header  :contains "List-Id" "<fulldisclosure.seclists.org>",
           header :contains "Subject" "mikrotik" ) {
    fileinto "INBOX/ML/SecList/Full Disclosure/mikrotik"; 
    stop;
}
# rule:[Seclist - Full-Disclosure]
# https://nmap.org/mailman/listinfo/fulldisclosure
if header :contains "List-Id" "<fulldisclosure.seclists.org>" { fileinto "INBOX/ML/SecList/Full Disclosure"; stop; }

# rule:[Seclist - oss-security]
# http://oss-security.openwall.org/wiki/mailing-lists/oss-security
if header :contains "List-Id" "<oss-security.lists.openwall.com>" { fileinto "INBOX/ML/SecList/Open Source Security"; stop; }

# rule:[Seclist - linux-distro]
# https://oss-security.openwall.org/wiki/mailing-lists/distros
if header :is "X-List" "vs.openwall.org" { fileinto "INBOX/ML/SecList/linux-distro"; stop; }

# rule:[Seclist - VINCE]
# https://kb.cert.org/vince/comm/auth/login/
if address :is "From" "cert+donotreply@cert.org" { fileinto "INBOX/ML/SecList/vince"; stop; }

# rule:[Seclist - infosecnews]
# http://lists.infosecnews.org/mailman/listinfo/isn_lists.infosecnews.org
if header :contains "List-Id" "<isn.lists.infosecnews.org>" { fileinto "INBOX/ML/SecList/Info Security News"; stop; }

# rule:[Seclist - CERT]
# https://public.govdelivery.com/accounts/USDHSCISA/subscriber/edit?preferences=true#tab1
if allof ( address :is "To" "${susede_email}",
           anyof ( address :contains "From" "US-CERT@ncas.us-cert.gov",
                   address :contains "From" "CISA@public.govdelivery.com" )) {
    fileinto "INBOX/ML/SecList/CERT Advisories";
    stop;
}

# rule:[openSSF - Announcements]
# https://lists.openssf.org/g/openssf-announcements
if header :contains "List-Id" "<openssf-announcements.lists.openssf.org>" { fileinto "INBOX/ML/OpenSSF/Announcements"; stop; }

# rule:[openSSF - Security threats]
# https://lists.openssf.org/g/openssf-wg-security-threats
if header :contains "List-Id" "<openssf-wg-security-threats.lists.openssf.org>" { fileinto "INBOX/ML/OpenSSF/Security Threats"; stop; }

# rule:[openSSF - Security tools]
# https://lists.openssf.org/g/openssf-wg-security-tooling
if header :contains "List-Id" "<openssf-wg-security-tooling.lists.openssf.org>" { fileinto "INBOX/ML/OpenSSF/Security Tooling"; stop; }

# rule:[openSSF - Vulnerability disclosures]
# https://lists.openssf.org/g/openssf-wg-vul-disclosures
if header :contains "List-Id" "<openssf-wg-vul-disclosures.lists.openssf.org>" { fileinto "INBOX/ML/OpenSSF/Vul Disclosures"; stop; }

# rule:[openSSF - Secure code best practices]
# https://lists.openssf.org/g/openssf-wg-best-practices
if header :contains "List-Id" "<openssf-wg-best-practices.lists.openssf.org>" { fileinto "INBOX/ML/OpenSSF/Code Best Practices"; stop; }

# rule:[Debian - security tracker mute bot]
##if allof ( header :contains "List-Id" "<debian-security-tracker.lists.debian.org>",
##           address :contains "From" "sectracker@soriano.debian.org") {
##    discard;
##    stop;
##}
# rule:[Debian - security tracker]
# https://lists.debian.org/debian-security-tracker/
if header :contains "List-Id" "<debian-security-tracker.lists.debian.org>" { fileinto "INBOX/ML/Debian/Security Tracker"; stop; }

# rule:[Debian - security announce]
# https://lists.debian.org/debian-security-announce/
if header :contains "List-Id" "<debian-security-announce.lists.debian.org>" { fileinto "INBOX/ML/Debian/Security Announce"; stop; }

#######################
##### NEWS LETTER #####
#######################
# NL
# └── LWN

# rule:[Security-News - LWN]
# https://lwn.net
if allof ( address :is "From" "lwn@lwn.net",
           address :is "To" "${susede_email}" ) {
    fileinto "INBOX/NL/LWN";
    stop;
}