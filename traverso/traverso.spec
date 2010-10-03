%ifarch %{ix86}
%global with_sse %{!?_without_sse:1}%{?_without_sse:0}
%elseifarch ia64 x86_64
%global with_sse 1
%endif
%ifnarch %{ix86} ia64 x86_64
%global with_sse 0
%endif

Name:           traverso
Version:        0.49.1
Release:        7%{?dist}
Summary:        Multitrack Audio Recording and Editing Suite
Group:          Applications/Multimedia
License:        GPLv2+
URL:            http://traverso-daw.org/
# Source0 actually is http://traverso-daw.org/download.html&d=%{name}-%{version}.tar.gz
# but rpmbuild doesn't work with this kind of URL's. So
Source0:        %{name}-%{version}.tar.gz
# lower the rtprio requirement to 20, for compliance with our jack
Patch0:         %{name}-priority.patch
# For convenience with enabling sse optimizations
# https://savannah.nongnu.org/bugs/index.php?26376
Patch1:         %{name}-sseopt.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  alsa-lib-devel
BuildRequires:  cmake
BuildRequires:  desktop-file-utils
BuildRequires:  fftw-devel
BuildRequires:  flac-devel
BuildRequires:  jack-audio-connection-kit-devel
BuildRequires:  lame-devel
BuildRequires:  libmad-devel
BuildRequires:  libogg-devel
BuildRequires:  libsamplerate-devel
BuildRequires:  libsndfile-devel
BuildRequires:  libvorbis-devel
BuildRequires:  portaudio-devel
# Native pulseaudio is not supported yet.
#BuildRequires:  pulseaudio-libs-devel
BuildRequires:  qt-devel
BuildRequires:  raptor-devel
BuildRequires:  redland-devel
BuildRequires:  slv2-devel >= 0.6.1
BuildRequires:  wavpack-devel

# For directory ownership:
Requires:       hicolor-icon-theme
Requires:       shared-mime-info

%description
Traverso Digital Audio Workstation is a cross platform multitrack audio 
recording  and editing suite, with an innovative and easy to master User
Interface. It's suited for both the professional and home user, who needs a
robust and solid DAW. 

Traverso is a complete solution from recording to CD Mastering. By supplying
many common tools in one package, you don't have to learn how to use lots of
applications with different user interfaces. This considerably lowers the 
learning curve, letting you get your audio processing work done faster!

A unique approach to non-linear audio processing was developed for Traverso to
provide extremely solid and robust audio processing and editing. Adding and 
removal of effects plugins, moving Audio Clips and creating new Tracks during 
playback are all perfectly safe, giving you instant feedback on your work! 

%prep
%setup -q
%patch0 -p1 -b .priority
%patch1 -p1 -b .sseopt

# Fix permission issues
chmod 644 ChangeLog TODO
for ext in h cpp; do
   find . -name "*.$ext" -exec chmod 644 {} \;
done

# We want to build these from source
rm -f resources/translations/*.qm

# To match the freedesktop standards
sed -i -e '\|^MimeType=.*[^;]$|s|$|;|' \
    resources/%{name}.desktop

# We use the system slv2, so just to make sure
rm -fr src/3rdparty/slv2

# For proper slv2 detection
sed -i 's|libslv2|slv2|g' CMakeLists.txt


%build
# Build the translations
pushd resources/translations
   for lang in *.ts; do
      lrelease-qt4 $lang
   done
popd

# Build the actual program
%{cmake}                                               \
         -DWANT_MP3_ENCODE=ON                          \
         -DUSE_SYSTEM_SLV2_LIBRARY=ON                  \
         -DDETECT_HOST_CPU_FEATURES=OFF                \
         -DWANT_PORTAUDIO=ON                           \
%if %{with_sse}
         -DWANT_SSE=ON                                 \
%endif
         .

make %{?_smp_mflags} VERBOSE=1 

# Add Comment to the .desktop file
echo "Comment=Digital Audio Workstation" >> resources/%{name}.desktop


%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot} 

# icons
install -dm 755 %{buildroot}%{_datadir}/icons/hicolor/
cp -a resources/freedesktop/icons/* %{buildroot}%{_datadir}/icons/hicolor/

# desktop file
install -dm 755 %{buildroot}%{_datadir}/applications/
desktop-file-install                          \
   --dir %{buildroot}%{_datadir}/applications \
   --remove-mime-type=text/plain              \
   --add-mime-type=application/x-traverso     \
   --remove-key=Path                          \
   resources/%{name}.desktop

# mime-type file
install -dm 755 %{buildroot}%{_datadir}/mime/packages/
install -pm 644 resources/x-%{name}.xml %{buildroot}%{_datadir}/mime/packages/

%clean
rm -rf %{buildroot}

%post
update-desktop-database &> /dev/null
touch --no-create %{_datadir}/icons/hicolor &>/dev/null
update-mime-database %{_datadir}/mime &> /dev/null || :

%postun
update-desktop-database &> /dev/null
if [ $1 -eq 0 ] ; then
    touch --no-create %{_datadir}/icons/hicolor &>/dev/null
    gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null
fi
update-mime-database %{_datadir}/mime &> /dev/null || :

%posttrans
gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :

%files
%defattr(-,root,root,-)
%doc AUTHORS ChangeLog COPYING COPYRIGHT HISTORY README TODO
%doc resources/projectconversion/2_to_3.html resources/help.text
%{_bindir}/%{name}
%{_datadir}/icons/hicolor/*/*/*
%{_datadir}/applications/%{name}.desktop
%{_datadir}/mime/packages/*.xml

%changelog
* Wed May 06 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-7
- Explicitly disable SSE optimizations on non-"%%{ix86} ia64 x86_64" architectures

* Wed May 06 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-6
- Re-enable portaudio

* Fri May 01 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-5
- Patch for dropping the rtprio requirement of traverso
- Drop the limits config file
- Drop the warnings patch

* Tue Apr 28 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-4
- Drop the defaults patch
- Fix slv2 library detection
- Add traversouser group
- Install limits config file in /etc/security/limits.d/

* Mon Apr 27 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-3
- Remove the supplied slv2 library in %%prep
- Add versioned BR to slv2 (>= 0.6.1)
- Drop the pdf manual
- Introduce new patch to handle the sse optimizations

* Thu Apr 16 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-2
- Change the default number of periods from 3 to 2
- Give a more verbose output if sound doesn't work
- Add the manual

* Sun Mar 29 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.1-1
- New upstream release
- Fix the year of the previous changelog entries
- Drop portaudio support. Upstream says that is unnecessary
- Drop pulseaudio support. Upstream says it is not ready yet
- Use system slv2 library instead of the shipped one

* Mon Mar 16 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.0-2
- Add disttag
- Disable automatic host cpu features detection while building and manually select 
  the cpu related flags
- Minor adjustment in %%postun: Use "|| :" only in the last command
- Minor adjustment in the .desktop file: Add trailing ";" to MimeType

* Sun Mar 15 2009 Orcan Ogetbil <oget [DOT] fedora [AT] gmail [DOT] com> - 0.49.0-1
- Initial build
