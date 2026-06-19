interface AvatarProps {
  src?: string;
  name?: string;
  size?: number;
  className?: string;
}

export function Avatar({ src, name = '?', size = 40, className = '' }: AvatarProps) {
  const initial = name.charAt(0).toUpperCase();
  const dim = { width: size, height: size, fontSize: Math.round(size * 0.4) };
  if (src) {
    return (
      <img
        src={src}
        alt={name}
        style={dim}
        className={`rounded-full object-cover bg-line ${className}`}
        onError={(e) => {
          (e.currentTarget as HTMLImageElement).style.display = 'none';
        }}
      />
    );
  }
  return (
    <div
      style={dim}
      className={`rounded-full bg-gradient-to-br from-blush to-terracotta text-white flex items-center justify-center font-medium ${className}`}
    >
      {initial}
    </div>
  );
}
