Name:           perl-BTLib
Version:        0.23
Release:        5%{?dist}
Summary:        Biology Toolkit Library Perl module

License:        GPL or Artistic
URL:            http://estscan.sourceforge.net
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  perl
BuildRequires:  perl(ExtUtils::MakeMaker)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This Perl module provides objects useful for parsing and extracting
information from DNA, protein, and other type of textual data found in biology
sequence analysis and bioinformatics, e.g., EMBL/GenBank and UniProt/SwissProt.

It also provides scripts to index and retrieve records from databases in flat
files.


%prep
%setup -q
# Help RPM depsolver find the requirements
sed -i 's+/usr/bin/env perl+%{_bindir}/perl+' fetch indexer netfetch


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="$RPM_OPT_FLAGS"
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*

mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/BTLib
install -m644 fetch.conf ${RPM_BUILD_ROOT}%{_sysconfdir}/BTLib/fetch.conf
install -m644 netfetch.conf ${RPM_BUILD_ROOT}%{_sysconfdir}/BTLib/netfetch.conf


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files
%dir %{_sysconfdir}/BTLib/
%config(noreplace) %{_sysconfdir}/BTLib/fetch.conf
%config(noreplace) %{_sysconfdir}/BTLib/netfetch.conf
%{_bindir}/fetch
%{_bindir}/indexer
%{_bindir}/netfetch
%{perl_vendorarch}/*.pm
%{perl_vendorarch}/auto/BTLib/
%{_mandir}/man3/*.3*


%changelog
* Tue Mar 14 2023 Christian Iseli <christian.iseli@unil.ch> 0.23-5
- Need to fix file path before glob (christian.iseli@unil.ch)

* Thu Mar 09 2023 Christian Iseli <christian.iseli@unil.ch> 0.23-4
- Fix file location detection in .ptr index files (christian.iseli@unil.ch)

* Mon Mar 06 2023 Christian Iseli <christian.iseli@unil.ch> 0.23-3
- update for tito build (christian.iseli@unil.ch)

* Mon Mar 06 2023 Christian Iseli <christian.iseli@unil.ch> 0.23-2
- update for tito build (christian.iseli@unil.ch)

* Mon Mar 06 2023 Christian Iseli <christian.iseli@unil.ch> 0.23-1
- new package built with tito

* Mon Mar 06 2023 Christian Iseli <Christian.Iseli@unil.ch> 0.23-1
- new package built with tito

* Mon Mar  6 2023 Christian Iseli <christian.iseli@epfl.ch> - 0.23-0
- version 0.23
- add BASE=. line in fetch.conf to get relative PATH

* Mon Aug  2 2021 Christian Iseli <christian.iseli@epfl.ch> - 0.22-0
- version 0.22
- fix change field width in .ptr index files

* Thu May 13 2021 Christian Iseli <christian.iseli@epfl.ch> - 0.21-0
- version 0.21
- change field width in .ptr index files
- fix defined check in ESTScan

* Mon Nov 19 2018 Christian Iseli <christian.iseli@sib.swiss> - 0.20-0
- version 0.20
- use tmpnam from File::Temp
- cleanup spec file

* Wed Jun 17 2009 Christian Iseli <Christian.Iseli@licr.org> - 0.19-0
- version 0.19
- remove || : after %%check

* Wed Sep 17 2008 Christian Iseli <Christian.Iseli@licr.org> - 0.18-0
- version 0.18

* Tue Mar 27 2007 Christian Iseli <Christian.Iseli@licr.org> - 0.17-0
- version 0.17

* Thu Feb  1 2007 Christian Iseli <Christian.Iseli@licr.org> - 0.16-0
- version 0.16

* Tue Dec 19 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.15-0
- version 0.15

* Fri Nov 24 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.14-0
- version 0.14

* Fri Nov  3 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.13-0
- version 0.13

* Fri Oct 27 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.12-0
- version 0.12

* Wed Oct 25 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.11-0
- version 0.11

* Tue Oct 24 2006 Christian Iseli <Christian.Iseli@licr.org> - 0.10-0
- created
