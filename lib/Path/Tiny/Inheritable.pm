#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Drop-in replacement for Path::Tiny that allows inheritance
#####################################################################

package Path::Tiny::Inheritable;

use 5.008001;
use strict;
use warnings;

# Coordinate with Path::Tiny version
our $VERSION = '0.076.001';
our @ISA;
BEGIN {
    require Path::Tiny;
    Path::Tiny->VERSION('0.076');
    push @ISA, 'Path::Tiny';
}

use Carp ();

# Exporter - mimic Path::Tiny
use Exporter 5.57 qw(import);
our @EXPORT = qw(path);
our @EXPORT_OK = qw(
    cwd
    rootdir
    tempfile
    tempdir
);

use constant {
    # Where Path::Tiny stores temp file/dir flag
    TEMP => 5,
};

use overload (
    q'""'    => sub    { $_[0]->stringify },
    q'@{}'   => sub    { $_[0]->path_tiny },
    bool     => sub () { 1 },
    fallback => 1,
);

# Enable serialization protocols - inheritance-safe
sub FREEZE { return $_[0]->stringify }
sub THAW   { return $_[0]->new($_[2]) }
{ no warnings 'once'; *TO_JSON = *FREEZE; }

# Annoying copy of Path::Tiny code
# Required because Path::Tiny is so unfriendly to subclassing
my $HAS_UU;
sub _check_UU {
    unless (defined $HAS_UU) {
        $HAS_UU = Path::Tiny::_check_UU();
    }
    return $HAS_UU;
}

#####################################################################

# Constructors

sub path {
    __PACKAGE__->new(@_);
}

sub new {
    my $class = shift;

    # Enable construction from object
    if (ref $class) {
        $class = ref $class;
    }

    Carp::croak("$class paths require defined, positive-length parts")
        unless @_ == grep { defined && length } @_;

    my $first = shift;

    # Already a Path::Tiny::Inheritable object (or child)
    if (!@_ and eval { $first->isa(__PACKAGE__) }) {
        # Non-temp objects are immutable and can be reused
        if (!$first->[TEMP]) {
            # Bless into appropriate class if necessary
            return ref $first eq $class
                ? $first
                : bless $first, $class;
        }
    }

    # Already a Path::Tiny object - just wrap and bless
    if (!@_ and ref $first eq 'Path::Tiny') {
        return bless { path => $first }, $class;
    }

    my $self = {
        # Path::Tiny already stringifies each piece
        path => Path::Tiny::path($first, @_),
    };

    bless $self, $class;
}

sub cwd {
    my $class = defined $_[0] ? shift : __PACKAGE__;
    $class->new(Path::Tiny::cwd());
}

sub rootdir {
    my $class = defined $_[0] ? shift : __PACKAGE__;
    $class->new(Path::Tiny::rootdir());
}

sub tempfile {
    my $class = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
    $class->new(Path::Tiny::tempfile(@_));
}

sub tempdir {
    my $class = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
    $class->new(Path::Tiny::tempdir(@_));
}

#####################################################################

# New method

sub path_tiny {
    return $_[0]->{path};
}

#####################################################################

# OVERRIDDEN METHODS

# absolute
#   Constructor wrapper

sub absolute {
    my $self = shift;
    my $return = $self->SUPER::absolute(@_);
    # Constructor could cause temp file/dir destruction
    # if absolute returns $self
    return (ref($return) eq ref($self))
        ? $return
        : $self->new($return);
}

# append_raw, append_utf8
#   Manual redefinition because Path::Tiny uses append($self)
#   instead of $self->append.

sub append_raw {
    my $self = shift;
    my $args = (@_ and ref($_[0]) eq 'HASH') ? shift : {};
    $args->{binmode} = ':unix';
    $self->append($args, @_);
}

sub append_utf8 {
    my $self = shift;
    my $args = (@_ and ref($_[0]) eq 'HASH') ? shift : {};
    if (_check_UU()) {
        $args->{binmode} = ':unix';
        $self->append($args, map { Unicode::UTF8::encode_utf8($_) } @_);
    }
    else {
        $args->{binmode} = ':unix:encoding(UTF-8)';
        $self->append($args, @_);
    }
}

# child
#   Constructor wrapper

sub child {
    my $self = shift;
    return $self->new(
        $self->SUPER::child(@_)
    );
}

# children
#   Constructor wrapper

sub children {
    my $self = shift;
    # Don't bother constructing the objects in scalar context
    return wantarray
        ? map { $self->new($_) } $self->SUPER::children(@_)
        : scalar $self->SUPER::children(@_);
}

# copy
#   Constructor wrapper

sub copy {
    my $self = shift;
    return $self->new(
        $self->SUPER::copy(@_)
    );
}

# iterator
#   Had to redefine because it needs a constructor wrapper
#   and checks ref $self eq Path::Tiny

sub iterator {
    my $self = shift;
    my $args = Path::Tiny::_get_args(shift, qw(recurse follow_symlinks));
    my @dirs = $self;
    my $current;
    return sub {
        my $next;
        while (@dirs) {
            if (eval { $dirs[0]->isa(__PACKAGE__) }) {
                if ( !-r $dirs[0] ) {
                    # Directory is missing or not readable, so skip it.
                    # There is a race condition possible between the
                    # check and the opendir, but we can't easily
                    # differentiate between error cases that are OK to
                    # skip and those that we want to be exceptions, so we
                    # live with the race and let opendir be fatal.
                    shift @dirs and next;
                }
                $current = $dirs[0];
                my $dh;
                opendir( $dh, $current->stringify )
                    or $self->_throw('opendir', $current->stringify);
                $dirs[0] = $dh;
                if ( -l $current && !$args->{follow_symlinks} ) {
                    # Symlink attack! It was a real dir, but is now a
                    # symlink!
                    # N.B. we check *after* opendir so the attacker has
                    # to win two races: replace dir with symlink before
                    # opendir and replace symlink with dir before -l
                    # check above
                    shift @dirs and next;
                }
            }
            while (defined( $next = readdir $dirs[0] )) {
                next if $next eq '.' || $next eq '..';
                my $path = $current->child($next);
                push @dirs, $path
                    if $args->{recurse} && -d $path
                        && !( !$args->{follow_symlinks} && -l $path );
                return $path;
            }
            shift @dirs;
        }
        return;
    };
}

# lines_raw
#   Manual redefinition because Path::Tiny uses slurp_raw($self)
#   and lines($self) instead of $self->slurp_raw and $self->lines.

sub lines_raw {
    my $self = shift;
    my $args = Path::Tiny::_get_args(shift, qw(binmode chomp count));
    if ($args->{chomp} && !$args->{count}) {
        return split /\n/, $self->slurp_raw;
    }
    else {
        $args->{binmode} = ':raw';
        return $self->lines($args);
    }
}

# lines_utf8
#   Manual redefinition because Path::Tiny uses slurp_utf8($self)
#   and lines($self) instead of $self->slurp_utf8 or $self->lines.

sub lines_utf8 {
    my $self = shift;
    my $args = Path::Tiny::_get_args(shift, qw(binmode chomp count));
    if (_check_UU() && $args->{chomp} && !$args->{count}) {
        return split /(?:\x{0d}?\x{0a}|\x{0d})/, $self->slurp_utf8;
    }
    else {
        $args->{binmode} = ':raw:encoding(UTF-8)';
        return $self->lines($args);
    }
}

# parent
#   Constructor wrapper

sub parent {
    my $self = shift;
    return $self->new(
        $self->SUPER::parent(@_)
    );
}

# realpath
#   Constructor wrapper

sub realpath {
    my $self = shift;
    return $self->new(
        $self->SUPER::realpath(@_)
    );
}

# relative
#   Constructor wrapper

sub relative {
    my $self = shift;
    return $self->new(
        $self->SUPER::relative(@_)
    );
}

# sibling
#   Constructor wrapper

sub sibling {
    my $self = shift;
    return $self->new(
        $self->SUPER::sibling(@_)
    );
}

# slurp_raw
#   Manual redefinition because Path::Tiny uses goto &slurp.

sub slurp_raw {
    my $self = shift;
    $self->slurp({ binmode => ':unix'});
}

# slurp_utf8
#   Manual redefinition because Path::Tiny uses slurp($self)
#   instead of $self->slurp.  Also Path::Tiny uses goto &slurp.

sub slurp_utf8 {
    my $self = shift;
    if (_check_UU()) {
        return Unicode::UTF8::decode_utf8(
            $self->slurp({ binmode => ':unix' })
        );
    }
    else {
        return $self->slurp({ binmode => ':raw:encoding(UTF-8)' });
    }
}

# spew
#   Manual redefinition because Path::Tiny force-creates a
#   Path::Tiny temp file object for spewing before moving
#   the file to the desired location, thereby disallowing
#   overloaded subclass methods.

sub spew {
    my $self = shift;
    my $args = (@_ && ref $_[0] eq 'HASH') ? shift : {};
    $args = Path::Tiny::_get_args($args, qw(binmode));
    my $binmode = $args->{binmode};
    # get default binmode from caller's lexical scope (see "perldoc open")
    $binmode = ( (caller(0))[10] || {} )->{'open>'} unless defined $binmode;

    # spewing needs to follow the link
    # and create the tempfile in the same dir
    my $resolved_path = $self->stringify;
    $resolved_path = readlink $resolved_path while -l $resolved_path;

    my $temp = $self->new($resolved_path . $$ . int(rand(2**31)));
    my $fh = $temp->filehandle(
        { exclusive => 1, locked => 1 }, ">", $binmode
    );
    print {$fh} map { ref eq 'ARRAY' ? @$_ : $_ } @_;
    close $fh or $self->_throw('close', $temp->stringify);

    return $temp->move($resolved_path);
}

# spew_raw
#   Manual redefinition because Path::Tiny uses goto &spew.

sub spew_raw {
    my $self = shift;
    $self->spew({ binmode => ':unix' }, @_);
}

# spew_utf8
#   Manual redefinition because Path::Tiny uses spew($self)
#   instead of $self->spew.  Path::Tiny also uses goto &spew.

sub spew_utf8 {
    my $self = shift;
    if (_check_UU()) {
        return $self->spew(
            { binmode => ':unix' },
            map { Unicode::UTF8::encode_utf8($_) } @_
        );
    }
    else {
        return $self->spew({ binmode => ':unix:encoding(UTF-8)' }, @_);
    }
}

# subsumes
#   Manual redefinition because Path::Tiny creates Path::Tiny object
#   of argument, therefore disallowing any overloaded methods

sub subsumes {
    my $self = shift;
    
    Carp::croak("subsumes() requires a defined, positive-length argument")
        unless defined $_[0];

    my $other = $self->new(shift);

    # normalize absolute vs relative
    if ($self->is_absolute && !$other->is_absolute) {
        $other = $other->absolute;
    }
    elsif ($other->is_absolute && !$self->is_absolute) {
        $self = $self->absolute;
    }

    # normalize volume vs non-volume; do the after absolute path
    # adjustments above since that might add volumes already
    if (length $self->volume && !length $other->volume) {
        $other = $other->absolute;
    }
    elsif (length $other->volume && !length $self->volume) {
        $self = $self->absolute;
    }

    if ( $self->stringify eq '.' ) {
        # cwd subsumes everything relative
        return !!1;
    }
    elsif ( $self->is_rootdir ) {
        # a root directory (/, c:/) already ends with a separator
        return $other->stringify =~ m{^\Q$self\E};
    }
    else {
        # exact match or prefix breaking at a separator
        return $other->stringify =~ m{^\Q$self\E(?:/|$)};
    }
}

#####################################################################

1;

__END__

=head1 SYNOPSIS

  package My::Path::Tiny;

  use parent qw(Path::Tiny::Inheritable Exporter);
  our @EXPORT = qw(path);

  # Subroutine constructor must be redefined to replicate
  #   Path::Tiny behavior
  sub path {
      __PACKAGE__->new(@_);
  }

=head2 DESCRIPTION

Drop-in replacement for Path::Tiny that enables inheritance.

As such, it is less "tiny" than Path::Tiny, but does adhere
to a more traditional object-oriented design.

Features of this drop-in replacement:

  - All Path::Tiny methods are available*

  - All constructors (except 'path') may be called with a
    bare class name or as a method from an existing object.
      Ex: 
        my $path1 = Path::Tiny::Inheritable->new(...);
        my $path2 = $path1->new(...);

  - Path::Tiny methods which return Path::Tiny objects
    have been overloaded to return objects constructed
    using $self->new(), guaranteeing that they will
    be of the same class type as $self.

  - Auto-stringification is enabled and inheritable.

  * Note: Some Path::Tiny methods are actually copied and
    modified instead of inherited because they do not
    adhere to OO-design.

The only new method available in Path::Tiny::Inheritable
is ->path_tiny, which returns the Path::Tiny object stored
in $self.

=head2 DETAILS OF INHERITANCE

Subclasses of Path::Tiny::Inheritable inherit the following
"CLASSNAME->new()"-style constructors:

  CLASSNAME->new()
  CLASSNAME->cwd()
  CLASSNAME->rootdir()
  CLASSNAME->tempfile()
  CLASSNAME->tempdir()

There is no CLASSNAME->path() interface for the classic 'path'
constructor.  The path constructor is not inheritable but if it
is desired by the subclass, it can be defined simply as follows:

  sub path {
      __PACKAGE__->new(@_);
  }

If subroutine-style constructors are desired for the remaining
constructors (as in Path::Tiny), the following is the recommended
way to do so (in order to preserve inheritability for any child
classes):

  sub cwd {
      my $class = shift // __PACKAGE__;
      $class->SUPER::cwd;
  }

  sub rootdir {
      my $class = shift // __PACKAGE__;
      $class->SUPER::rootdir;
  }

  # tempfile,tempdir may accept arguments
  #   so it is necessary to test whether
  #   the first argument looks like
  #   a classname or calling object
  sub tempfile {
      my $class = eval { $_[0]->isa(__PACKAGE__) }
          ? shift
          : __PACKAGE__;
      $class->SUPER::tempfile;
  }

  sub tempdir {
      my $class = eval { $_[0]->isa(__PACKAGE__) }
          ? shift
          : __PACKAGE__;
      $class->SUPER::tempdir;
  }

=head1 BEST PRACTICES FOR ADDING/OVERRIDING METHODS

=head2 Use $self->new() instead of path()

If the subclass overrides or defines a new method which
returns a path object, in order to preserve inheritance,
use the $self->new() style of construction instead of
__PACKAGE__->new() or path().

=head2 OVERRIDING new()

This package relies heavily on the fact that $self->new(...)
constructs a new object of the same type as $self.  Overriding
new() is certainly allowed, but must implement that same
behavior, otherwise things will almost certainly break.

The structure of the Path::Tiny::Inheritable object is simply
this:

  { path => <Path::Tiny object> }

If an overridden new constructor changes where the Path::Tiny
object is stored, the path_tiny method must also be overridden
in order for inherited methods to work.

=head1 ADDITIONAL METHOD

=head2 path_tiny

Return the embedded Path::Tiny object stored in $self.

=head1 SEE ALSO

  Path::Tiny

=cut
